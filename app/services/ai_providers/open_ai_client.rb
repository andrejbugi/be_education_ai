require "base64"
require "json"
require "net/http"
require "uri"

module AiProviders
  class OpenAIClient < BaseClient
    API_URI = URI("https://api.openai.com/v1/responses")

    def initialize(
      api_key: ENV["OPENAI_API_KEY"],
      model: ENV["OPENAI_MODEL"].presence || "gpt-4.1-mini",
      api_key_base64: ENV["OPENAI_API_KEY_BASE64"]
    )
      @api_key = normalize_api_key(api_key, api_key_base64)
      @model = model
    end

    def generate_tutor_response(prompt:)
      raise ArgumentError, "OPENAI_API_KEY is missing" if api_key.blank?

      body = perform_request(prompt)
      content = body["output_text"].presence || extract_output_text(body)
      raise "OpenAI response did not include output text" if content.blank?

      Response.new(
        content: content,
        metadata: {
          "provider" => "openai",
          "model" => model
        }
      )
    end

    private

    attr_reader :api_key, :model

    def normalize_api_key(api_key, api_key_base64)
      return api_key if api_key.blank?
      return api_key unless ActiveModel::Type::Boolean.new.cast(api_key_base64)

      Base64.strict_decode64(api_key.to_s).strip
    rescue ArgumentError
      raise ArgumentError, "OPENAI_API_KEY is not valid base64"
    end

    def perform_request(prompt)
      request = Net::HTTP::Post.new(API_URI)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(
        {
          model: model,
          instructions: prompt[:system_instructions],
          input: prompt[:user_input]
        }
      )

      response = Net::HTTP.start(API_URI.hostname, API_URI.port, use_ssl: true) do |http|
        http.read_timeout = 30
        http.open_timeout = 10
        http.request(request)
      end

      parsed = JSON.parse(response.body)
      return parsed if response.is_a?(Net::HTTPSuccess)

      raise "OpenAI request failed: #{response.code} #{parsed["error"]&.dig("message") || response.body}"
    end

    def extract_output_text(body)
      Array(body["output"]).flat_map { |entry| Array(entry["content"]) }
                           .filter_map { |content| content["text"] if content["type"] == "output_text" }
                           .join("\n")
                           .strip
    end
  end
end
