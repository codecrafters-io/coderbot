require "test_helper"

class AbandonStaleAutofixRequestsJobTest < ActiveJob::TestCase
  test "jobs are valid" do
    scheduled_jobs = Resque.schedule

    scheduled_jobs.each do |_scheduled_job_key, scheduled_job_args|
      job_class = scheduled_job_args["args"][0]["job_class"]
      assert Object.const_defined?(job_class), "Job class #{job_class} does not exist"
    end
  end
end
