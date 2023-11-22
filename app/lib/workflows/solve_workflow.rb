class Workflows::SolveWorkflow < Workflows::BaseWorkflow
  attr_accessor :solver

  def initialize(solver:)
    super()

    @solver = solver
  end

  def run
    solver.with_cloned_repository do |local_repository|
      run_tests_step = Steps::RunTestsStep.new(
        workflow: self,
        stage: solver.course_stage,
        local_repository: local_repository,
        logstream: solver.logstream
      )

      run_tests_step.perform
      run_tests_step.success?
    end
  end
end
