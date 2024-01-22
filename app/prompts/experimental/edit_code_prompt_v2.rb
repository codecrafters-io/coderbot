class Experimental::EditCodePromptV2 < BasePrompt
  provider :azure, deployment_name: "gpt-35-turbo"
  # provider :azure, deployment_name: "gpt-4-1106-preview"

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

      - Format your output as a unified diff similar to that `diff -U0` would produce.
      - Make sure you include the first 2 lines with the file names
      - Don't leave out any lines or the diff patch won't apply correctly
      - Only output hunks corresponding to changes the user asks for in the <edit-instructions> block. Don't make any other changes.
      - Start a new hunk for each section of the file that needs changes.
      - When editing a function, method, loop, etc use a hunk to replace the *entire* code block. Delete the entire existing version with `-` lines and then add a new, updated version with `+` lines. This will help you generate correct code and correct diffs.

      For example, if the user asks you to remove lines 34-36, you should output:

      ```diff
      --- a/file.txt
      +++ b/file.txt
      @@ -34,3 +34,0 @@
      -<contents of line 34>
      -<contents of line 35>
      -<contents of line 36>
      ```

      If the user asks you to move the function `foo` from line 20 to line 30, you should output something like:

      ```diff
      --- a/file.txt
      +++ b/file.txt
      @@ -20,3 +20,3 @@
      -def foo
      -  puts "bar"
      -end
      @@ -30,3 +30,3 @@
      +def foo
      +  puts "bar"
      +end
      ```
    PROMPT
  end

  def user_message(original_code, edit_instructions_markdown)
    <<~PROMPT
      Here's my code:

      <code>
      #{original_code}
      </code>

      Provide diffs to edit this code based on the instructions formatted in markdown below:

      <edit-instructions>
      #{edit_instructions_markdown}
      </edit-instructions>
    PROMPT
  end
end
