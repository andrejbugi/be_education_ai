module AiTutor
  class GenerateResponse
    Result = Struct.new(:success?, :message, :errors, keyword_init: true)

    def initialize(ai_session:, user_message:)
      @ai_session = ai_session
      @user_message = user_message
    end

    def call
      prompt = BuildPrompt.new(ai_session: ai_session, user_message: user_message).call
      provider_response = generate_provider_response(prompt)

      assistant_result = AiMessages::Append.new(
        ai_session: ai_session,
        params: {
          role: :assistant,
          message_type: resolve_message_type(prompt),
          content: provider_response.content,
          metadata: response_metadata(prompt, provider_response)
        }
      ).call

      if assistant_result.success?
        Result.new(success?: true, message: assistant_result.message, errors: [])
      else
        Result.new(success?: false, message: assistant_result.message, errors: assistant_result.errors)
      end
    rescue StandardError => e
      fallback_result = append_fallback_error_message(e)
      return Result.new(success?: true, message: fallback_result.message, errors: []) if fallback_result.success?

      Result.new(success?: false, message: fallback_result.message, errors: fallback_result.errors)
    end

    private

    attr_reader :ai_session, :user_message

    def generate_provider_response(prompt)
      client = AiProviders::ClientFactory.build
      client.generate_tutor_response(prompt: prompt)
    rescue StandardError => e
      fallback = AiProviders::MockClient.new.generate_tutor_response(prompt: prompt)
      fallback.metadata["requested_provider"] = client.class.name.demodulize.underscore
      fallback.metadata["fallback_reason"] = e.message
      fallback
    end

    def resolve_message_type(prompt)
      step_answer_status = prompt.dig(:submission_step_answer, :status)
      step_answer_status == "incorrect" ? :feedback : :hint
    end

    def response_metadata(prompt, provider_response)
      provider_response.metadata.merge(
        "generated_for_message_id" => user_message.id,
        "assignment_id" => ai_session.assignment_id,
        "submission_id" => ai_session.submission_id,
        "assignment_step_id" => prompt.dig(:assignment_step, :id)
      ).compact
    end

    def append_fallback_error_message(error)
      AiMessages::Append.new(
        ai_session: ai_session,
        params: {
          role: :assistant,
          message_type: :error,
          content: "Моментално не можам да одговорам. Кажи ми што проба досега и ќе продолжиме чекор по чекор.",
          metadata: {
            "provider" => "fallback",
            "generated_for_message_id" => user_message.id,
            "error" => error.message
          }
        }
      ).call
    end
  end
end
