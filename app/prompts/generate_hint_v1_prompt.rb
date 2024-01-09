class GenerateHintV1Prompt < BasePrompt
  model "gpt-4-1106-preview" # TODO: Change to turbo
  provider :azure, deployment_name: "gpt-4-1106-preview"

  # Context: course, stage, language, changed_files, test_runner_output
  def call
    logstream = BufferedWriter.new(MultiWriter.new(*[ENV["DEBUG"].eql?("true") ? $stdout : nil, context.logstream].compact))

    context.result = chat(
      [{role: "user", content: user_message(context.stage, context.language, context.changed_files, context.test_runner_output)}],
      seed: context.seed,
      logstream: logstream
    )

    logstream.flush
  end

  protected

  def format_changed_file(changed_file, language)
    <<~MARKDOWN
      ```diff-#{language.slug}
      #{changed_file["diff"]}
      ```
    MARKDOWN
  end

  def user_message(stage, language, changed_files, test_runner_output)
    <<~PROMPT
      You are a brilliant and meticulous coding tutor. You are helping a student by explaining how to fix their code so that it passes stage #{stage.position} of the "#{stage.course.name}" programming course.

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

      The user is asking you for guidance on how to fix their #{language.name} code to pass this stage.

      When they submitted their code, they saw the following error delimited by triple backticks below:

      <test-runner-error-message>

      #{test_runner_output.compilation_failed? ? test_runner_output.raw_output : test_runner_output.last_stage_logs_without_colors}

      </test-runner-error-message>

      Your assistant was able to fix the user's code so that it passes the stage. There are #{changed_files.count} changed file(s) in the assistant's diff:

      #{changed_files.map { |changed_file| format_changed_file(changed_file, language) }.join("\n\n")}

      Your goal is to generate an explanation based on the diff above. This explanation should help the user fix their code. Keep in mind that the user is a
      beginner, so their understanding of #{language.name} might be limited.

      Here are some rules to follow:

      * Only explain the primary bug (the one most related to the test runner output above), don't explain every single change in the diff.
      * Explain how the user should fix the bug, don't fix it for them.
      * Keep your explanation short and to the point.

      Reply with your explanation in markdown format below. Start your explanation with "It looks like...".
    PROMPT
  end
end
