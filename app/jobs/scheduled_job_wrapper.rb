# Rails doesn't play well with resque-scheduler by default.
class ScheduledJobWrapper
  def self.perform(args)
    args["job_class"].constantize.perform_later
  end

  def self.wrap(schedule)
    # from: https://github.com/rails/rails/issues/16933#issuecomment-58945932
    schedule.each do |k, v|
      next unless v["class"] != "ScheduledJobWrapper"
      q = v["queue"] || "default"

      schedule[k] = {
        class: "ScheduledJobWrapper",
        description: v["description"],
        queue: q,
        cron: v["cron"],
        every: v["every"],
        args: [
          {
            job_class: v["class"],
            queue_name: q,
            arguments: v["arguments"]
          }
        ]
      }
    end
  end
end
