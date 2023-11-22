dataset_dir = File.expand_path(ARGV[0])
limit = ARGV[1] ? ARGV[1].to_i : 10000

RESULTS_DIR = Rails.root.join("tmp", "dataset_validations_results", "#{File.basename(dataset_dir)}-#{Time.now.iso8601[0..18].tr(":", ".")}")
FileUtils.mkdir_p(RESULTS_DIR)

submission_dirs = Dir.glob("#{dataset_dir}/*").take(limit)

def relative_solver_logs_path(solver)
  solver_logs_path(solver).relative_path_from(Rails.root)
end

def solver_dir(solver)
  Rails.root.join(RESULTS_DIR, solver.status)
end

def solver_json_path(solver)
  Rails.root.join(solver_dir(solver), "#{solver.friendly_id}.json")
end

def solver_logs_path(solver)
  Rails.root.join(solver_dir(solver), "#{solver.friendly_id}.log")
end

solvers = submission_dirs.pmap(8) do |submission_dir|
  submission_data = JSON.parse(File.read(File.join(submission_dir, "data.json")))

  # Sanity check
  course = Course.find_by_slug!(submission_data.fetch("course_slug"))
  course.stages.detect { |stage| stage.slug == submission_data.fetch("course_stage_slug") } || raise(ActiveRecord::RecordNotFound)

  logstream_url = "redis://localhost:6911/#{SecureRandom.uuid}"

  solver = Solver.create!(
    repository_clone_url: "file:///#{submission_dir}/code",
    last_submission_commit_sha: submission_data.fetch("submission_commit_sha"),
    last_successful_submission_commit_sha: submission_data.fetch("last_successful_submission_commit_sha"),
    language_slug: submission_data.fetch("language_slug"),
    course_slug: submission_data.fetch("course_slug"),
    logstream_url: logstream_url,
    course_stage_slug: submission_data.fetch("course_stage_slug")
  )

  puts "Validating #{solver.friendly_id}"
  RunSolverJob.perform_now(solver)
  solver.logstream.terminate!

  FileUtils.mkdir_p(solver_dir(solver))

  File.write(solver_logs_path(solver), solver.logstream.read)

  File.write(
    solver_json_path(solver),
    {
      status: solver.status,
      duration_ms: ((solver.updated_at - solver.created_at) * 1000)
    }.to_json
  )

  solver
end

puts "Results written to #{RESULTS_DIR}"

aggregate_results_file_path = File.join(RESULTS_DIR, "aggregate_results.json")

aggregate_results = {
  "total" => solvers.count,
  "success" => solvers.count { |solver| solver.status == "success" },
  "failure" => solvers.count { |solver| solver.status == "failure" },
  "error" => solvers.count { |solver| solver.status == "error" },
  "success_percentage" => (solvers.count { |solver| solver.status == "success" }.to_f / solvers.count * 100).round(2)
}

File.write(aggregate_results_file_path, aggregate_results.to_json)

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
puts "Aggregate results written to #{aggregate_results_file_path}."
