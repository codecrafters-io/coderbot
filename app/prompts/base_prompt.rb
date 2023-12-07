class BasePrompt
  include Interactor

  class << self
    attr_accessor :model_name
    attr_accessor :response_format
  end

  # DSL
  def self.model(name)
    @model_name = name
  end

  # DSL
  def self.respond_with(format)
    raise "Invalid response format: #{format}" unless %i[text json].include?(format.to_sym)
    self.response_format = format.to_sym
  end

  def chat(messages, should_stream: true, **parameters)
    result = ""

    client.chat(
      parameters: {
        model: self.class.model_name || raise("model_name not set, please set it with `model \"model-name\"`"),
        messages: messages,
        response_format: {
          type: if self.class.response_format.eql?(:json)
                  "json_object"
                else
                  "text"
                end
        },
        seed: rand(1000000), # Default, can be overridden using parameters
        stream: proc do |chunk, _bytesize|
          if chunk.dig("choices", 0, "finish_reason") == "stop" # last message
            print "\n" if should_stream && Rails.env.development?
            next
          end

          content = chunk.dig("choices", 0, "delta", "content")
          unless content.nil?
            print content if should_stream && Rails.env.development?
            result += content
          end
        end,
        **parameters
      }
    )

    if self.class.response_format.eql?(:json)
      JSON.parse(result)
    else
      result
    end
  end

  def client
    @client ||= OpenAI::Client.new(
      access_token: ENV.fetch("AZURE_OPENAI_API_KEY"),
      uri_base: "https://oai.hconeai.com/openai/deployments/gpt-4-1106-preview",
      request_timeout: 240,
      extra_headers: {
        "api-key": ENV.fetch("AZURE_OPENAI_API_KEY"),
        "Helicone-Auth": "Bearer #{ENV.fetch("HELICONE_API_KEY")}",
        "Helicone-OpenAI-Api-Base": ENV.fetch("AZURE_OPENAI_ENDPOINT"),
        "Helicone-Property-Prompt": self.class.name,
        "helicone-stream-force-format": "true"
      },
      api_type: :azure,
      api_version: "2023-03-15-preview"
    )
  end
end
