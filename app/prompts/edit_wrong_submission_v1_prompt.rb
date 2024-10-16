class EditWrongSubmissionV1Prompt < BasePrompt
  model "gpt-4o-mini"
  provider :azure, deployment_name: "gpt-4o-mini"

  # model "gpt-3.5-turbo-1106" # Temporary, until we do optimized edits

  # Context: course, stage, language, original_code, test_runner_output
  def call
    logstream = BufferedWriter.new(MultiWriter.new(*[ENV["DEBUG"].eql?("true") ? $stdout : nil, context.logstream].compact))

    context.result = chat(
      [{role: "user", content: user_message(context.stage, context.language, context.original_code, context.test_runner_output)}],
      seed: context.seed,
      logstream: logstream
    )

    logstream.flush
  end

  protected

  def user_message(stage, language, original_code, test_runner_output)
    <<~PROMPT
      You are a brilliant and meticulous engineer assigned to write code to pass stage #{stage.position} of the "#{stage.course.name}" programming course.

      The description of the course is below:

      <description>

      #{stage.course.description_markdown}

      </description>

      The course has multiple stages, the previous stage was stage "#{stage.previous_stage.name}" and the current stage is stage "#{stage.name}".

      The instructions for the previous stage are in markdown below:

      <previous-stage-instructions>

      # Stage: #{stage.previous_stage.name}

      #{stage.previous_stage.description_markdown_for_language(language)}

      </previous-stage-instructions>

      The instructions for the current stage are in markdown below:

      <current-stage-instructions>

      # Stage: #{stage.name}

      #{stage.description_markdown_for_language(language)}

      </current-stage-instructions>

      The user is asking you to help them edit their #{language.name} code to pass this stage. The user's code is listed below delimited by triple backticks:

      ```#{language.syntax_highlighting_identifier}
      #{original_code}
      ```

      When they submitted their code, they saw the following error delimited by triple backticks below:

      <test-runner-error-message>

      #{test_runner_output.compilation_failed? ? test_runner_output.raw_output : test_runner_output.last_stage_logs_without_colors}

      </test-runner-error-message>

      Your goal is to fix the user's code so that it passes the stage. Keep in mind that the user is a beginner, so their code might
      contain mistakes that you wouldn't typically make.

      First, think through what the bug might be. Then, print out a plan to fix the bug. Once you have the plan, implement it by editing
      the user's code. Print the FULL contents of the edited file delimited by triple backticks.

      Here are some rules to follow:

      * Keep your changes minimal. Only make minor edits, don't rewrite large portions of the code.
      * Write production-quality code. Don't leave in any commented-out code or unused variables.
      * Don't change existing comments unless they're incorrect or outdated.
      * Don't add comments to your code.
      * IMPORTANT: Print the FULL contents of the edited file delimited by triple backticks. Don't print partial contents of the file.
    PROMPT
  end
end
