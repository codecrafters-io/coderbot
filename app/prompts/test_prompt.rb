class TestPrompt < BasePrompt
  model "gpt-4-1106-preview" # TODO: Change to turbo
  # provider :azure, deployment_name: "gpt-4-1106-preview"

  def call
    context.result = chat(
      [{role: "user", content: "hi!"}],
      seed: 1,
      logstream: $stdout
    )
  end
end
