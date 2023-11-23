class EditWrongSubmissionV1Prompt < BasePrompt
  model "gpt-4-1106-preview" # TODO: Change to turbo

  # Context: course, stage, language, original_code, test_runner_output
  def call
    context.result = chat(
      [{role: "user", content: user_message(context.stage, context.language, context.original_code, context.test_runner_output)}],
      seed: context.seed,
      should_stream: ENV["DEBUG"].eql?("true")
    )
  end

  protected

  def user_message(stage, language, original_code, test_runner_output)
    <<~PROMPT
      You are a brilliant and meticulous engineer assigned to write code to pass stage #{stage.position} of the "#{stage.course.name}" programming course.

      The description of the course is below delimited by "--- DESCRIPTION START ---" and "--- DESCRIPTION END ---":

      --- DESCRIPTION START ---

      #{stage.course.description_markdown}

      --- DESCRIPTION END ---

      The course has multiple stages, the previous stage was stage "#{stage.previous_stage.name}" and the current stage is stage "#{stage.name}".

      The instructions for the previous stage are in markdown below delimited by "--- PREVIOUS STAGE INSTRUCTIONS START ---" and "--- PREVIOUS STAGE INSTRUCTIONS END ---":

      --- PREVIOUS STAGE INSTRUCTIONS START ---

      # Stage: #{stage.previous_stage.name}

      #{stage.previous_stage.description_markdown_for_language(language)}

      --- PREVIOUS STAGE INSTRUCTIONS END ---

      The instructions for the current stage are in markdown below delimited by "--- CURRENT STAGE INSTRUCTIONS START ---" and "--- CURRENT STAGE INSTRUCTIONS END ---":

      --- CURRENT STAGE INSTRUCTIONS START ---

      # Stage: #{stage.name}

      #{stage.description_markdown_for_language(language)}

      --- CURRENT STAGE INSTRUCTIONS END ---

      The user is asking you to help them edit their code to pass this stage. The user's code is listed below delimited by triple backticks:

      ```#{language.syntax_highlighting_identifier}
      #{original_code}
      ```

      When they submitted their code, they saw the following error delimited by triple backticks below:

      ```
      #{test_runner_output.compilation_failed? ? test_runner_output.raw_output : test_runner_output.last_stage_logs_without_colors}
      ```

      Your goal is to fix the user's code so that it passes the stage.

      First, think through what the bug might be. Then, print out a plan to fix the bug. Once you have the plan, implement it by editing
      the user's code. Print the FULL contents of the edited file delimited by triple backticks.

      Here are some rules to follow:

      * Keep your changes minimal. Only make minor edits, don't rewrite large portions of the code.
      * Add comments to explain your changes, and don't remove existing comments unless they're incorrect or outdated.
      * If you see obvious mistakes, fix them. The user is a beginner, so their code might contain mistakes that you wouldn't typically make.
      * IMPORTANT: Print the FULL contents of the edited file delimited by triple backticks. Don't print partial contents of the file.
    PROMPT
  end
end
