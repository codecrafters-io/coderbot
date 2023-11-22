class RunSolverJob < ApplicationJob
  def perform(solver)
    # Reserve first
    solver.with_lock do
      return unless solver.not_started?

      solver.started!
    end

    workflow = Workflows::SolveWorkflow.new(solver: solver)
    workflow.run!

    if workflow.success?
      solver.success!
    else
      solver.failure!
    end
  rescue => e
    puts e.backtrace.reverse.join("\n")
    puts "Error: #{e.message}"
    solver.error!
  end
end
