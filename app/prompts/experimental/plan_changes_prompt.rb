class Experimental::PlanChangesPrompt < BasePrompt
  model "gpt-4-1106-preview" # TODO: Change to turbo
  provider :azure, deployment_name: "gpt-4-1106-preview"

  # model "gpt-3.5-turbo-1106" # Temporary, until we do optimized edits

  # Context: course, stage, language, original_code, test_runner_output
  def call
    logstream = BufferedWriter.new(MultiWriter.new(*[ENV["DEBUG"].eql?("true") ? $stdout : nil, context.logstream].compact))

    context.result = chat(
      [
        {role: "system", content: system_message(context.stage, context.language)},
        {role: "user", content: user_message(context.stage, context.language, context.original_code, context.test_runner_output)}
      ],
      seed: context.seed,
      logstream: logstream
    )

    if context.result.match?(/<fix-plan>/)
      context.result = context.result.match(/<fix-plan>(.*?)<\/fix-plan>/m)[1]
    end

    logstream.flush
  end

  protected

  def system_message(stage, language)
    <<~PROMPT
      You are a brilliant and meticulous engineer assigned to review code and suggest changes to pass stage #{stage.position} of the "#{stage.course.name}" programming course.

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

      The user will provide their #{language.name} code and the error message they saw when they submitted their code.

      Your goal is to identify the most likely bug that prevents them from passing this stage.

      First, think through what the bug might be. Then, print out a plan to fix the bug.

      Here are some rules to follow:

      - Surround your plan with `<fix-plan>` and `</fix-plan>` tags.
      - Format your plan as a markdown list.
      - Keep your plan to 3 steps or less. If you think there's more than one bug, just fix the most important one.
      - Be concise.
      - Make each step as specific as possible. For example, instead of saying "Add a `print()` method", say "Add a `print()` method below the `inspect()` method".
      - Don't print the edited code, just print out the plan. Someone else will edit the code.
      - A junior engineer will be implementing your plan, so make sure it's easy to follow.
      - Keep your suggested changes minimal, only suggest changes necessary to pass the current stage.

      Here's an example of a plan:

      <fix-plan>
      - Remove the `stream.print()` line.
      - Add stream=True to the `open()` call.
      </fix-plan>
    PROMPT
  end

  def user_message(stage, language, original_code, test_runner_output)
    <<~PROMPT
      I'm trying to pass the '#{stage.name}' stage of the "#{stage.course.name}" programming course.

      Here's my #{language.name} code:

      ```#{language.syntax_highlighting_identifier}
      #{original_code}
      ```

      I saw this error when submitting my code:

      <test-runner-error-message>

      #{test_runner_output.compilation_failed? ? test_runner_output.raw_output : test_runner_output.last_stage_logs_without_colors}

      </test-runner-error-message>

      Please review my code and suggest a plan to fix the bug that prevents me from passing this stage.
    PROMPT
  end
end
