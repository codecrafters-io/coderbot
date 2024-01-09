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

      run_tests_steps = []
      attempt_fix_steps = []

      loop do
        counter += 1

        run_tests_step = Steps::RunTestsStep.new(
          autofix_request: autofix_request,
          workflow: self,
          stage: autofix_request.course_stage,
          local_repository: local_repository,
          logstream: autofix_request.logstream
        )

        run_tests_step.run!
        run_tests_steps << run_tests_step

        # TEMP
        # failure!
        # autofix_request.explanation_markdown = <<~MARKDOWN
        #   Failure.
        # MARKDOWN

        # break

        if run_tests_step.success?
          raise "test passed on first try (#{autofix_request.course_slug}/#{autofix_request.language_slug})" if counter == 1

          success!

          break
        end

        if counter >= 5
          autofix_request.explanation_markdown = <<~MARKDOWN
            We tried to fix your submission, but we failed. Trying again _might_ help.

            You can view the raw logs to see what fixes we tried and what errors we ran into.
          MARKDOWN

          failure!
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
        attempt_fix_steps << attempt_fix_step
      end

      ended_at = Time.now

      if success?
        final_code = File.read(local_repository.code_file_path)

        autofix_request.changed_files = [
          {
            diff: Diffy::Diff.new(original_code, final_code).to_s,
            filename: local_repository.relative_code_file_path
          }
        ]

        autofix_request.logstream.info("Generating hint...")
        autofix_request.logstream.append("\n")

        autofix_request.explanation_markdown = GenerateHintV1Prompt.call!(
          course: autofix_request.course_stage.course,
          stage: autofix_request.course_stage,
          language: autofix_request.language,
          changed_files: autofix_request.changed_files,
          test_runner_output: run_tests_steps[0].test_runner_output,
          logstream: autofix_request.logstream
        ).result
      end

      autofix_request.steps_count = counter
      autofix_request.duration_ms = (ended_at - started_at) * 1000
      autofix_request.save!
    end
  end
end
