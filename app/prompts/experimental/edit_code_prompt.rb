class Experimental::EditCodePrompt < BasePrompt
  # provider :azure, deployment_name: "gpt-35-turbo"
  provider :azure, deployment_name: "gpt-4-1106-preview"
  model "dummy"

  # Context: original_code, edit_instructions
  def call
    context.result = chat(
      [
        {role: "system", content: system_message},
        {role: "user", content: user_message(context.original_code, context.edit_instructions_markdown)}
      ],
      logstream: nil
    )
  end

  protected

  def system_message
    <<~PROMPT
      The user will ask you to edit some code.

      - Print the edited code directly, don't include ``` or any other extra formatting.
      - Only make the changes the user asks for in the <edit-instructions> block. Don't make any other changes.
      - Don't add extra comments unless the user asks for them.
    PROMPT
  end

  def user_message(original_code, edit_instructions_markdown)
    <<~PROMPT
      Here's my code:

      <code>
      #{original_code}
      </code>

      Edit this code based on the instructions formatted in markdown below:

      <edit-instructions>
      #{edit_instructions_markdown}
      </edit-instructions>
    PROMPT
  end
end
