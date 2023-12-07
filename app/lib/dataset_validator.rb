class DatasetValidator
  # Inputs
  attr_accessor :dataset_dir

  # Objects
  attr_accessor :mlflow_run

  # Counters
  attr_accessor :finished_counter
  attr_accessor :success_counter
  attr_accessor :error_counter

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

    autofix_requests = submission_dirs.pmap(16) do |submission_dir|
      submission_data = JSON.parse(File.read(File.join(submission_dir, "data.json")))
      create_autofix_request_from_submission_data!(submission_dir, submission_data)
    end

    course_slugs = autofix_requests.map(&:course_slug).uniq

    course_slugs.peach(16) do |course_slug|
      TesterDownloader.new(Course.find_by_slug!(course_slug)).download_if_needed
    end

    autofix_requests.peach(16) do |autofix_request|
      puts "Validating #{autofix_request.friendly_id} (#{autofix_request.course_slug}/#{autofix_request.language_slug}})"

      ProcessAutofixRequestJob.perform_now(autofix_request)

      FileUtils.mkdir_p(autofix_request_dir(autofix_request))
      write_autofix_request_logs!(autofix_request)
      write_autofix_request_data!(autofix_request)
      increment_counters!(autofix_request)
      update_readings!(autofix_request)
      log_metrics!

      # This doesn't actually work yet
      mlflow_run.log_artifact(autofix_request_json_path(autofix_request), "results/#{autofix_request.friendly_id}.json")
      mlflow_run.log_artifact(autofix_request_logs_path(autofix_request), "logs/#{autofix_request.friendly_id}.log")
    end

    finish_mlflow_run!
    write_and_print_aggregate_results!(autofix_requests)
    print_results_table!(autofix_requests)
  end

  protected

  def autofix_request_dir(autofix_request)
    File.join(results_dir, autofix_request.status)
  end

  def autofix_request_json_path(autofix_request)
    File.join(autofix_request_dir(autofix_request), "#{autofix_request.friendly_id}.json")
  end

  def autofix_request_logs_path(autofix_request)
    File.join(autofix_request_dir(autofix_request), "#{autofix_request.friendly_id}.log")
  end

  def create_autofix_request_from_submission_data!(submission_dir, submission_data)
    id = SecureRandom.uuid

    autofix_request.create!(
      id: id,
      course_slug: submission_data.fetch("course_slug"),
      course_stage_slug: submission_data.fetch("course_stage_slug"),
      language_slug: submission_data.fetch("language_slug"),
      submission_commit_sha: submission_data.fetch("submission_commit_sha"),
      last_successful_submission_commit_sha: submission_data.fetch("last_successful_submission_commit_sha"),
      logstream_url: "redis://localhost:6911/#{id}",
      repository_clone_url: "file:///#{submission_dir}/code"
    )
  end

  def finish_mlflow_run!
    mlflow_run.finish!
  end

  def increment_counters!(autofix_request)
    finished_counter.increment
    success_counter.increment if autofix_request.status == "success"
    error_counter.increment if autofix_request.status == "error"
  end

  def init_counters!
    self.finished_counter = Concurrent::AtomicFixnum.new(0)
    self.success_counter = Concurrent::AtomicFixnum.new(0)
    self.error_counter = Concurrent::AtomicFixnum.new(0)
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

    error_rate = (error_counter.value.to_f / finished_counter.value) * 100
    mlflow_run.log_metric(finished_counter.value, "error_rate", error_rate)

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

  def print_results_table!(autofix_requests)
    rows = autofix_requests.map do |autofix_request|
      [
        autofix_request.friendly_id,
        "#{autofix_request.course_slug}/#{autofix_request.language_slug}",
        autofix_request.status,
        autofix_request.status.eql?("success") ? autofix_request.changed_lines_count : "-",
        autofix_request.status.eql?("success") ? autofix_request.steps_count : "-",
        autofix_request.status.eql?("success") ? "#{autofix_request.duration_secs}s" : "-",
        autofix_request.status.eql?("error") ? autofix_request.error_message : "-"
      ]
    end

    table = Terminal::Table.new headings: ["ID", "Course/Lang", "Status", "Diff size", "Steps count", "Duration", "Notes"], rows: rows
    puts table
  end

  def relative_autofix_request_logs_path(autofix_request)
    Pathname.new(autofix_request_logs_path(autofix_request)).relative_path_from(Rails.root)
  end

  def results_dir
    @results_dir ||= Rails.root.join("tmp", "dataset_validations_results", "#{File.basename(dataset_dir)}-#{Time.now.iso8601[0..18].tr(":", ".")}")
  end

  def submission_dirs_in_dataset
    Dir.glob("#{dataset_dir}/*").sort
  end

  def update_readings!(autofix_request)
    if autofix_request.status == "success"
      step_count_readings.concat([autofix_request.steps_count])
      diff_size_readings.concat([autofix_request.changed_lines_count])
      duration_readings.concat([autofix_request.duration_ms])
    end
  end

  def write_and_print_aggregate_results!(autofix_requests)
    aggregate_results_file_path = File.join(results_dir, "aggregate_results.json")

    aggregate_results = {
      "total" => autofix_requests.count,
      "success" => autofix_requests.count { |autofix_request| autofix_request.status == "success" },
      "failure" => autofix_requests.count { |autofix_request| autofix_request.status == "failure" },
      "error" => autofix_requests.count { |autofix_request| autofix_request.status == "error" },
      "success_percentage" => (autofix_requests.count { |autofix_request| autofix_request.status == "success" }.to_f / autofix_requests.count * 100).round(2)
    }

    File.write(aggregate_results_file_path, aggregate_results.to_json)

    puts "Results written to #{results_dir}"
    puts ""
    autofix_requests.select { |autofix_request| autofix_request.status == "success" }.each do |autofix_request|
      puts "Success: #{autofix_request.friendly_id} (#{relative_autofix_request_logs_path(autofix_request)})"
    end
    puts ""
    autofix_requests.reject { |autofix_request| autofix_request.status == "success" }.each do |autofix_request|
      puts "#{autofix_request.status}: #{autofix_request.friendly_id} (#{relative_autofix_request_logs_path(autofix_request)}}"
    end
    puts ""

    puts "Failure: #{aggregate_results.fetch("failure")}"
    puts "Success: #{aggregate_results.fetch("success")}"
    puts "Total: #{aggregate_results.fetch("total")}"
    puts "Success percentage: #{aggregate_results.fetch("success_percentage")}%"
    puts ""
  end

  def write_autofix_request_data!(autofix_request)
    File.write(
      autofix_request_json_path(autofix_request),
      {
        status: autofix_request.status,
        duration_ms: autofix_request.duration_ms
      }.to_json
    )
  end

  def write_autofix_request_logs!(autofix_request)
    File.write(autofix_request_logs_path(autofix_request), autofix_request.logstream.read)
  end
end
