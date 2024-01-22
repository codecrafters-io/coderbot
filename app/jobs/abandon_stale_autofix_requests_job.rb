class AbandonStaleAutofixRequestsJob < ApplicationJob
  def perform
    AutofixRequest.not_finalized.where("created_at < ?", 4.minutes.ago).each do |autofix_request|
      EventLogger.info(
        "autofix_request.abandoned",
        autofix_request_id: autofix_request.id,
        language_slug: autofix_request.language_slug,
        course_slug: autofix_request.course_slug,
        course_stage_slug: autofix_request.course_stage_slug
      )

      autofix_request.with_lock do
        autofix_request.logstream.write("This autofix request was cancelled because it took more than 5 minutes to run. If this looks like a bug, please contact us at hello@codecrafters.io.")
        autofix_request.update!(status: "error", explanation_markdown: "This autofix request was cancelled because it took more than 5 minutes to run. If this looks like a bug, please contact us at hello@codecrafters.io")
      end
    rescue => e
      if Rails.env.production?
        Sentry.capture_exception(e)
      else
        raise e
      end
    end
  end
end
