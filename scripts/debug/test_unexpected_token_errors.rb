client = OpenAI::Client.new(
  access_token: ENV.fetch("AZURE_OPENAI_API_KEY"),
  uri_base: "https://oai.hconeai.com/openai/deployments/gpt-35-turbo",
  request_timeout: 240,
  extra_headers: {
    "api-key": ENV.fetch("AZURE_OPENAI_API_KEY"),
    "Helicone-Auth": "Bearer #{ENV.fetch("HELICONE_API_KEY")}",
    "Helicone-OpenAI-Api-Base": ENV.fetch("AZURE_OPENAI_ENDPOINT"),
    "Helicone-Property-Prompt": "TestUnexpectedTokenErrorsPrompt",
    # "helicone-stream-force-format": "true"
  },
  api_type: :azure,
  api_version: "2023-03-15-preview"
)

# client = OpenAI::Client.new(
#   access_token: ENV.fetch("AZURE_OPENAI_API_KEY"),
#   uri_base: "https://coderbot.openai.azure.com/openai/deployments/gpt-35-turbo",
#   request_timeout: 240,
#   extra_headers: {
#     "api-key": ENV.fetch("AZURE_OPENAI_API_KEY")
#   },
#   api_type: :azure,
#   api_version: "2023-03-15-preview"
# )

100.times.peach(8) do |i|
  start_time = Time.now

  puts ""
  puts "Iteration #{i}"
  puts ""

  client.chat(
    parameters: {
      model: "gpt-3.5-turbo",
      messages: [
        {role: "user", content: "Write me 3 paragraphs about the topic 'OpenAI parsing needs to be fixed'"}
      ],
      response_format: {type: "text"},
      seed: i, # Default, can be overridden using parameters
      stream: proc do |chunk, _bytesize|
        if chunk.dig("choices", 0, "finish_reason") == "stop" # last message
          puts ""
          puts "Iteration #{i} finished. Took #{(Time.now - start_time).round(2)} seconds."
          puts ""

          next
        end

        content = chunk.dig("choices", 0, "delta", "content")
        unless content.nil?
          $stdout.write(".")
        end
      end
    }
  )
end
