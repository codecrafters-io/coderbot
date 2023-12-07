class Workflows::SolveWorkflow < Workflows::BaseWorkflow
  attr_accessor :autofix_request

  def initialize(autofix_request:)
    super()

    @autofix_request = autofix_request
    @identifier = autofix_request.friendly_id
  end

  def do_run!
    autofix_request.with_cloned_repository do |local_repository|
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
          stage: autofix_request.course_stage,
          local_repository: local_repository,
          logstream: autofix_request.logstream
        )

        run_tests_step.run!

        if run_tests_step.success?
          raise "test passed on first try (#{autofix_request.course_slug}/#{autofix_request.language_slug})" if counter == 1
          success!

          break
        end

        attempt_fix_step = Steps::AttemptFixStep.new(
          workflow: self,
          stage: autofix_request.course_stage,
          local_repository: local_repository,
          test_runner_output: run_tests_step.test_runner_output,
          logstream: autofix_request.logstream
        )

        attempt_fix_step.run!
      end

      ended_at = Time.now
      final_code = File.read(local_repository.code_file_path)

      autofix_request.final_diff = Diffy::Diff.new(original_code, final_code).to_s
      autofix_request.steps_count = counter
      autofix_request.duration_ms = (ended_at - started_at) * 1000
      autofix_request.save!
    end
  end
end
