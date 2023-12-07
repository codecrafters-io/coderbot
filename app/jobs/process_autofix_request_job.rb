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
    puts e.backtrace.reverse.join("\n")
    puts "Error: #{e.message}"
    autofix_request.update!(explanation_markdown: "Autofix ran into an error: ```\n#{e.message}\n```.\n\nTry again? Contact us at hello@codecrafters.io if this persists.", status: "error")
  ensure
    autofix_request.logstream.terminate!
  end
end
