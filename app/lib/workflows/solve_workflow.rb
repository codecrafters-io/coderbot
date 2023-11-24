class Workflows::SolveWorkflow < Workflows::BaseWorkflow
  attr_accessor :solver

  def initialize(solver:)
    super()

    @solver = solver
    @identifier = solver.friendly_id
  end

  def do_run!
    solver.with_cloned_repository do |local_repository|
      started_at = Time.now
      original_code = File.read(local_repository.code_file_path)
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
          raise "test passed on first try (#{solver.course_slug}/#{solver.language_slug})" if counter == 1
          success!

          break
        end

        attempt_fix_step = Steps::AttemptFixStep.new(
          workflow: self,
          stage: solver.course_stage,
          local_repository: local_repository,
          test_runner_output: run_tests_step.test_runner_output,
          logstream: solver.logstream
        )

        attempt_fix_step.run!
      end

      ended_at = Time.now
      final_code = File.read(local_repository.code_file_path)

      solver.final_diff = Diffy::Diff.new(original_code, final_code).to_s
      solver.steps_count = counter
      solver.duration_ms = (ended_at - started_at) * 1000
      solver.save!
    end
  end
end
