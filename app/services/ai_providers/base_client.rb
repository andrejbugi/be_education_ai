module AiProviders
  class BaseClient
    Response = Struct.new(:content, :metadata, keyword_init: true)

    def generate_tutor_response(prompt:)
      raise NotImplementedError, "#{self.class.name} must implement #generate_tutor_response"
    end
  end
end
