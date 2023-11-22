dataset_dir = File.expand_path(ARGV[0])

results_dir = Rails.root.join("tmp", "dataset_validations_results", "#{File.basename(dataset_dir)}-#{Time.now.iso8601[0..18].tr(":", ".")}")
FileUtils.mkdir_p(results_dir)

Dir.glob("#{dataset_dir}/*").peach(8) do |submission_dir|
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

  RunSolverJob.perform_now(solver)
  solver.logstream.terminate!

  File.write(File.join(results_dir, "#{solver.id}.log"), solver.logstream.read)
  File.write(File.join(results_dir, "#{solver.id}.json"), {status: solver.status}.to_json)
end

puts "Results written to #{results_dir}"

aggregate_results_file_path = File.join(results_dir, "aggregate_results.json")
File.write(
  aggregate_results_file_path,
  {
    "total" => Dir.glob("#{results_dir}/*.json").count,
    "success" => Dir.glob("#{results_dir}/*.json").count { |path| JSON.parse(File.read(path)).fetch("status") == "success" },
    "failure" => Dir.glob("#{results_dir}/*.json").count { |path| JSON.parse(File.read(path)).fetch("status") == "failure" },
    "error" => Dir.glob("#{results_dir}/*.json").count { |path| JSON.parse(File.read(path)).fetch("status") == "error" }
  }.to_json
)

puts "Aggregate results written to #{aggregate_results_file_path}"
