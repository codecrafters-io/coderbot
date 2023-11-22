solver = Solver.create!(
  repository_clone_url: "dummy",
  last_submission_commit_sha: "dummy",
  last_successful_submission_commit_sha: "dummy",
  language_slug: "dummy",
  course_slug: "dummy",
  logstream_url: "dummy",
  course_stage_slug: "dummy"
)

RunSolverJob.perform_now(solver)
