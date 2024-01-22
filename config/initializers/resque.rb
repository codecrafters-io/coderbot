require "resque-scheduler"
require "resque/scheduler/server"

require "active_support/all" # Required for #present?

require_relative "../../app/jobs/scheduled_job_wrapper"

if ENV["ACTIVE_JOB_REDIS_URL"].present?
  Resque.redis = Redis.new(
    url: ENV["ACTIVE_JOB_REDIS_URL"],
    ssl_params: {verify_mode: OpenSSL::SSL::VERIFY_NONE}
  )

  Resque.schedule = ScheduledJobWrapper.wrap(YAML.load_file("config/resque_schedule.yml"))
end
