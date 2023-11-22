class RunSolverJob < ApplicationJob
  def perform(solver)
    # Reserve first
    solver.with_lock do
      return unless solver.not_started?

      solver.started!
    end

    if solver.run
      solver.success!
    else
      solver.failure!
    end
  rescue => e
    solver.error!(e)
  end
end
