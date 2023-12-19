class ProcessAutofixRequestJob < ApplicationJob
  def perform(autofix_request)
    # Reserve first
    autofix_request.with_lock do
      return unless autofix_request.not_started?

      autofix_request.in_progress!
    end

    # Use this to short-circuit the autofix_request
    # autofix_request.failure!
    # return

    workflow = Workflows::SolveWorkflow.new(autofix_request: autofix_request)
    workflow.run!

    if workflow.success?
      autofix_request.success!
    else
      autofix_request.failure!
    end
  rescue => e
    Sentry.capture_exception(e)

    puts e.backtrace.reverse.join("\n")
    puts "Error: #{e.message}"

    explanation_markdown = <<~ERR
      Autofix ran into an error:

      ```
      #{e.message}
      ```

      Try again? Contact us at hello@codecrafters.io if this persists.
    ERR

    autofix_request.update!(status: "error", explanation_markdown: explanation_markdown)
  ensure
    if autofix_request.codecrafters_server_url.present?
      CodecraftersServerGateway.new.notify_autofix_request_completed(autofix_request_id: autofix_request.id, codecrafters_server_url: autofix_request.codecrafters_server_url)
    end
  end
end
