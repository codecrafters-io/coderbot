class TestPrompt < BasePrompt
  model "gpt-4-1106-preview" # TODO: Change to turbo

  def call
    context.result = chat(
      [{role: "user", content: "hi!"}],
      seed: 1,
      should_stream: true
    )
  end
end
