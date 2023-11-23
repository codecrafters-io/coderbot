class RunSolverJob < ApplicationJob
  def perform(solver)
    # Reserve first
    solver.with_lock do
      return unless solver.not_started?

      solver.started!
    end

    # Use this to short-circuit the solver
    # solver.failure!
    # return

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
  ensure
    solver.logstream.terminate!
  end
end
