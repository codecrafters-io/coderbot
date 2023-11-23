class DatasetValidator
  # Inputs
  attr_accessor :dataset_dir

  # Objects
  attr_accessor :mlflow_run

  # Counters
  attr_accessor :finished_counter
  attr_accessor :success_counter

  # Metrics
  attr_accessor :step_count_readings
  attr_accessor :diff_size_readings
  attr_accessor :duration_readings

  def initialize(dataset_dir)
    @dataset_dir = dataset_dir
  end

  def validate!(indexes: nil)
    submission_dirs = if indexes
      indexes.map { |index| submission_dirs_in_dataset[index] || raise("Submission not found at index #{index}") }
    else
      submission_dirs_in_dataset
    end

    init_store!
    init_results_dir!
    init_mlflow_run!
    init_counters!
    init_metrics!

    solvers = submission_dirs.pmap(16) do |submission_dir|
      submission_data = JSON.parse(File.read(File.join(submission_dir, "data.json")))
      create_solver_from_submission_data!(submission_dir, submission_data)
    end

    solvers.peach(16) do |solver|
      puts "Validating #{solver.friendly_id}"

      RunSolverJob.perform_now(solver)

      FileUtils.mkdir_p(solver_dir(solver))
      write_solver_logs!(solver)
      write_solver_data!(solver)
      increment_counters!(solver)
      update_metrics!(solver)
      log_metrics!

      # This doesn't actually work yet
      mlflow_run.log_artifact(solver_json_path(solver), "results/#{solver.friendly_id}.json")
      mlflow_run.log_artifact(solver_logs_path(solver), "logs/#{solver.friendly_id}.log")
    end

    finish_mlflow_run!
    write_and_print_aggregate_results!(solvers)
    print_results_table!(solvers)
  end

  protected

  def create_solver_from_submission_data!(submission_dir, submission_data)
    id = SecureRandom.uuid

    Solver.create!(
      id: id,
      course_slug: submission_data.fetch("course_slug"),
      course_stage_slug: submission_data.fetch("course_stage_slug"),
      language_slug: submission_data.fetch("language_slug"),
      last_submission_commit_sha: submission_data.fetch("submission_commit_sha"),
      last_successful_submission_commit_sha: submission_data.fetch("last_successful_submission_commit_sha"),
      logstream_url: "redis://localhost:6911/#{id}",
      repository_clone_url: "file:///#{submission_dir}/code"
    )
  end

  def finish_mlflow_run!
    mlflow_run.finish!
  end

  def increment_counters!(solver)
    finished_counter.increment
    success_counter.increment if solver.status == "success"
  end

  def init_counters!
    self.finished_counter = Concurrent::AtomicFixnum.new(0)
    self.success_counter = Concurrent::AtomicFixnum.new(0)
  end

  def init_metrics!
    self.step_count_readings = Concurrent::Array.new
    self.diff_size_readings = Concurrent::Array.new
    self.duration_readings = Concurrent::Array.new
  end

  def init_mlflow_run!
    self.mlflow_run = MlflowRun.create!

    mlflow_run.log_dataset(
      name: File.basename(dataset_dir),
      profile: "#{submission_dirs_in_dataset.size} entries"
    )

    mlflow_run.log_param("branch", ENV.fetch("GIT_BRANCH", `git rev-parse --abbrev-ref HEAD`.strip))
    mlflow_run.log_param("commit", `git rev-parse HEAD`.strip)
  end

  def init_results_dir!
    FileUtils.mkdir_p(results_dir)
  end

  def init_store!
    Store.ensure_loaded!
  end

  def log_metrics!
    success_rate = (success_counter.value.to_f / finished_counter.value) * 100
    mlflow_run.log_metric(finished_counter.value, "success_rate", success_rate)

    if step_count_readings.size > 0
      step_counts_average = step_count_readings.sum.to_f / step_count_readings.size
      mlflow_run.log_metric(finished_counter.value, "avg_step_count", step_counts_average)
    end

    if diff_size_readings.size > 0
      diff_sizes_average = diff_size_readings.sum.to_f / duration_readings.size
      mlflow_run.log_metric(finished_counter.value, "avg_diff_size", diff_sizes_average)
    end

    if duration_readings.size > 0
      duration_ms_average = duration_readings.sum.to_f / duration_readings.size
      mlflow_run.log_metric(finished_counter.value, "avg_duration_secs", duration_ms_average / 1000)
    end
  end

  def print_results_table!(solvers)
    rows = solvers.map do |solver|
      [
        solver.friendly_id,
        "#{solver.course_slug}/#{solver.language_slug}",
        solver.status,
        solver.changed_lines_count,
        solver.steps_count,
        "#{solver.duration_secs}s"
      ]
    end

    table = Terminal::Table.new headings: ["ID", "Course/Lang", "Status", "Diff size", "Steps count", "Duration"], rows: rows
    puts table
  end

  def relative_solver_logs_path(solver)
    Pathname.new(solver_logs_path(solver)).relative_path_from(Rails.root)
  end

  def results_dir
    @results_dir ||= Rails.root.join("tmp", "dataset_validations_results", "#{File.basename(dataset_dir)}-#{Time.now.iso8601[0..18].tr(":", ".")}")
  end

  def solver_dir(solver)
    File.join(results_dir, solver.status)
  end

  def solver_json_path(solver)
    File.join(solver_dir(solver), "#{solver.friendly_id}.json")
  end

  def solver_logs_path(solver)
    File.join(solver_dir(solver), "#{solver.friendly_id}.log")
  end

  def submission_dirs_in_dataset
    Dir.glob("#{dataset_dir}/*").sort
  end

  def update_metrics!(solver)
    if solver.status == "success"
      step_count_readings.concat([solver.steps_count])
      diff_size_readings.concat([solver.changed_lines_count])
      duration_readings.concat([solver.duration_ms])
    end
  end

  def write_and_print_aggregate_results!(solvers)
    aggregate_results_file_path = File.join(results_dir, "aggregate_results.json")

    aggregate_results = {
      "total" => solvers.count,
      "success" => solvers.count { |solver| solver.status == "success" },
      "failure" => solvers.count { |solver| solver.status == "failure" },
      "error" => solvers.count { |solver| solver.status == "error" },
      "success_percentage" => (solvers.count { |solver| solver.status == "success" }.to_f / solvers.count * 100).round(2)
    }

    File.write(aggregate_results_file_path, aggregate_results.to_json)

    puts "Results written to #{results_dir}"
    puts ""
    solvers.select { |solver| solver.status == "success" }.each do |solver|
      puts "Success: #{solver.friendly_id} (#{relative_solver_logs_path(solver)})"
    end
    puts ""
    solvers.reject { |solver| solver.status == "success" }.each do |solver|
      puts "#{solver.status}: #{solver.friendly_id} (#{relative_solver_logs_path(solver)}}"
    end
    puts ""

    puts "Failure: #{aggregate_results.fetch("failure")}"
    puts "Success: #{aggregate_results.fetch("success")}"
    puts "Total: #{aggregate_results.fetch("total")}"
    puts "Success percentage: #{aggregate_results.fetch("success_percentage")}%"
    puts ""
  end

  def write_solver_data!(solver)
    File.write(
      solver_json_path(solver),
      {
        status: solver.status,
        duration_ms: solver.duration_ms
      }.to_json
    )
  end

  def write_solver_logs!(solver)
    File.write(solver_logs_path(solver), solver.logstream.read)
  end
end
