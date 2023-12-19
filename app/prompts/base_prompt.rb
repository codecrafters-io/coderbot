class BasePrompt
  include Interactor

  class << self
    attr_accessor :model_name
    attr_accessor :provider_name
    attr_accessor :provider_params
    attr_accessor :response_format
  end

  # DSL
  def self.model(name)
    @model_name = name
  end

  # DSL
  def self.provider(name, **params)
    @provider_name = name
    @provider_params = params
  end

  # DSL
  def self.respond_with(format)
    raise "Invalid response format: #{format}" unless %i[text json].include?(format.to_sym)
    self.response_format = format.to_sym
  end

  def chat(messages, logstream: nil, **parameters)
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
            logstream&.write("\n")

            next
          end

          content = chunk.dig("choices", 0, "delta", "content")
          unless content.nil?
            logstream&.write(content)
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
    @client ||= case self.class.provider_name
    when :azure
      OpenAI::Client.new(
        access_token: ENV.fetch("AZURE_OPENAI_API_KEY"),
        uri_base: "https://oai.hconeai.com/openai/deployments/#{self.class.provider_params.fetch(:deployment_name)}",
        request_timeout: 240,
        extra_headers: {
          "api-key": ENV.fetch("AZURE_OPENAI_API_KEY"),
          "Helicone-Auth": "Bearer #{ENV.fetch("HELICONE_API_KEY")}",
          "Helicone-OpenAI-Api-Base": ENV.fetch("AZURE_OPENAI_ENDPOINT"),
          "Helicone-Property-Prompt": self.class.name,
        },
        api_type: :azure,
        api_version: "2023-03-15-preview"
      )
    else # :openai
      @client ||= OpenAI::Client.new(
        access_token: ENV["OPENAI_API_KEY"],
        uri_base: "https://oai.hconeai.com/",
        request_timeout: 240,
        extra_headers: {
          "Helicone-Auth": "Bearer #{ENV["HELICONE_API_KEY"]}",
          "Helicone-Property-Prompt": self.class.name,
        }
      )
    end
  end
end
