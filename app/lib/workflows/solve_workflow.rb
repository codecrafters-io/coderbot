class Workflows::SolveWorkflow < Workflows::BaseWorkflow
  attr_accessor :solver

  def initialize(solver:)
    super()

    @solver = solver
    @identifier = solver.friendly_submission_id
  end

  def do_run!
    solver.with_cloned_repository do |local_repository|
      counter = 0

      loop do
        counter += 1

        if counter >= 5
          failure!
          break
        end

        run_tests_step = Steps::RunTestsStep.new(
          workflow: self,
          stage: solver.course_stage,
          local_repository: local_repository,
          logstream: solver.logstream
        )

        run_tests_step.run!

        if run_tests_step.success?
          success!

          break
        end

        attempt_fix_step = Steps::AttemptFixStep.new(
          stage: solver.course_stage,
          local_repository: local_repository,
          test_runner_output: run_tests_step.test_runner_output,
          logstream: solver.logstream
        )

        attempt_fix_step.run!
      end
    end
  end
end
