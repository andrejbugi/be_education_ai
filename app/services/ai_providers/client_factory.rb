module AiProviders
  class ClientFactory
    def self.build
      provider = ENV["AI_PROVIDER"].to_s.strip.downcase

      if provider == "openai" && ENV["OPENAI_API_KEY"].present?
        OpenAIClient.new
      else
        MockClient.new
      end
    end
  end
end
