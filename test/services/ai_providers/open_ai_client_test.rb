require "test_helper"
require "base64"

class AiProviders::OpenAIClientTest < ActiveSupport::TestCase
  test "uses decoded api key when base64 flag is enabled" do
    encoded_key = Base64.strict_encode64("decoded-secret-key")
    client = AiProviders::OpenAIClient.new(api_key: encoded_key, api_key_base64: "true", model: "gpt-4.1-mini")
    request_capture = {}

    response = Net::HTTPOK.new("1.1", "200", "OK")
    response.instance_variable_set(:@body, { output_text: "Tutor response" }.to_json)

    def response.body
      @body
    end

    fake_http = Object.new
    fake_http.define_singleton_method(:read_timeout=) { |_value| nil }
    fake_http.define_singleton_method(:open_timeout=) { |_value| nil }
    fake_http.define_singleton_method(:request) do |request|
      request_capture[:authorization] = request["Authorization"]
      response
    end

    original_start = Net::HTTP.method(:start)
    Net::HTTP.define_singleton_method(:start) do |*args, **kwargs, &block|
      block.call(fake_http)
    end

    begin
      result = client.generate_tutor_response(
        prompt: {
          system_instructions: "Be helpful",
          user_input: "Help me start"
        }
      )

      assert_equal "Tutor response", result.content
    ensure
      Net::HTTP.define_singleton_method(:start, original_start)
    end

    assert_equal "Bearer decoded-secret-key", request_capture[:authorization]
  end

  test "raises helpful error when base64 flag is enabled but value is invalid" do
    error = assert_raises(ArgumentError) do
      AiProviders::OpenAIClient.new(api_key: "not-valid-base64", api_key_base64: "true")
    end

    assert_equal "OPENAI_API_KEY is not valid base64", error.message
  end
end
