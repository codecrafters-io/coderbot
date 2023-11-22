submission_dir = Rails.root.join("tmp", "datasets", "coderbot_dataset_7", "5c2f494e-d013-4c78-a0b0-8120bea52795")
submission_data = JSON.parse(File.read(submission_dir.join("data.json")))

# Sanity check
course = Course.find_by_slug!(submission_data.fetch("course_slug"))
course.stages.detect { |stage| stage.slug == submission_data.fetch("course_stage_slug") } || raise(ActiveRecord::RecordNotFound)

solver = Solver.create!(
  repository_clone_url: "file:///#{submission_dir}/code",
  last_submission_commit_sha: submission_data.fetch("submission_commit_sha"),
  last_successful_submission_commit_sha: submission_data.fetch("last_successful_submission_commit_sha"),
  language_slug: submission_data.fetch("language_slug"),
  course_slug: submission_data.fetch("course_slug"),
  logstream_url: "dummy",
  course_stage_slug: submission_data.fetch("course_stage_slug")
)

RunSolverJob.perform_now(solver)
puts solver.status
