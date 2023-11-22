dataset_dir = File.expand_path(ARGV[0])

results_dir = Rails.root.join("tmp", "dataset_validations_results", "#{File.basename(dataset_dir)}-#{Time.now.iso8601[0..18].tr(":", ".")}")
FileUtils.mkdir_p(results_dir)

solvers = Dir.glob("#{dataset_dir}/*").pmap(8) do |submission_dir|
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

  puts "Validating #{solver.friendly_submission_id}"
  RunSolverJob.perform_now(solver)
  solver.logstream.terminate!

  solver_dir = File.join(results_dir, solver.status)
  FileUtils.mkdir_p(solver_dir)

  File.write(File.join(solver_dir, "#{solver.friendly_submission_id}.log"), solver.logstream.read)

  File.write(
    File.join(solver_dir, "#{solver.friendly_submission_id}.json"),
    {
      status: solver.status,
      duration_ms: ((solver.updated_at - solver.created_at) * 1000)
    }.to_json
  )

  solver
end

puts "Results written to #{results_dir}"

aggregate_results_file_path = File.join(results_dir, "aggregate_results.json")

File.write(
  aggregate_results_file_path,
  {
    "total" => solvers.count,
    "success" => solvers.count { |solver| solver.status == "success" },
    "failure" => solvers.count { |solver| solver.status == "failure" },
    "error" => solvers.count { |solver| solver.status == "error" }
  }.to_json
)

puts "Aggregate results written to #{aggregate_results_file_path}"
