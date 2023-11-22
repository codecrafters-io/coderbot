class Workflows::SolveWorkflow < Workflows::BaseWorkflow
  attr_accessor :solver

  def initialize(solver:)
    super()

    @solver = solver
  end

  def failure?
    status == "failure"
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

      self.status = run_tests_step.success? ? "success" : "failure"
    end
  end

  def success?
    status == "success"
  end
end
