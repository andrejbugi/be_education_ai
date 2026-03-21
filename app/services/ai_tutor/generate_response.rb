module AiTutor
  class GenerateResponse
    MAX_RESPONSE_WORDS = 100

    RESOURCE_REQUEST_PATTERNS = [
      /линк/i,
      /линков/i,
      /извор/i,
      /извори/i,
      /ресурс/i,
      /ресурси/i,
      /сајт/i,
      /website/i,
      /site\b/i,
      /source/i,
      /sources/i,
      /youtube/i,
      /ютјуб/i,
      /video/i,
      /книга/i,
      /book/i,
      /presentation/i,
      /презентаци/i,
      /slides/i,
      /слајд/i
    ].freeze

    DO_WORK_PATTERNS = [
      /спреми ми/i,
      /спремиш/i,
      /подготви ми/i,
      /подготвиш/i,
      /направи ми/i,
      /одбери ми/i,
      /избери ми/i,
      /кажи ми за што да биде/i,
      /одлучи ти/i,
      /research it for me/i,
      /prepare it for me/i,
      /choose for me/i
    ].freeze

    STARTING_PATTERNS = [
      /how do i start/i,
      /where do i start/i,
      /how should i begin/i,
      /како да почнам/i,
      /од каде да почнам/i,
      /како да почнам да решавам/i
    ].freeze

    Result = Struct.new(:success?, :message, :errors, keyword_init: true)

    def initialize(ai_session:, user_message:)
      @ai_session = ai_session
      @user_message = user_message
    end

    def call
      prompt = BuildPrompt.new(ai_session: ai_session, user_message: user_message).call

      if restricted_help_request?
        return append_policy_message(prompt)
      end

      if starting_request?
        return append_starting_message(prompt)
      end

      provider_response = generate_provider_response(prompt)
      content = normalize_assistant_content(provider_response.content)

      assistant_result = AiMessages::Append.new(
        ai_session: ai_session,
        params: {
          role: :assistant,
          message_type: resolve_message_type(prompt),
          content: content,
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

    def restricted_help_request?
      question = user_message.content.to_s

      matches_any?(question, RESOURCE_REQUEST_PATTERNS) && matches_any?(question, DO_WORK_PATTERNS)
    end

    def starting_request?
      matches_any?(user_message.content.to_s, STARTING_PATTERNS)
    end

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

    def append_policy_message(prompt)
      result = AiMessages::Append.new(
        ai_session: ai_session,
        params: {
          role: :assistant,
          message_type: :hint,
          content: normalize_assistant_content(policy_message_content),
          metadata: {
            "provider" => "policy",
            "policy" => "resource_boundary",
            "generated_for_message_id" => user_message.id,
            "assignment_id" => ai_session.assignment_id,
            "submission_id" => ai_session.submission_id,
            "assignment_step_id" => prompt.dig(:assignment_step, :id)
          }.compact
        }
      ).call

      return Result.new(success?: true, message: result.message, errors: []) if result.success?

      Result.new(success?: false, message: result.message, errors: result.errors)
    end

    def append_starting_message(prompt)
      result = AiMessages::Append.new(
        ai_session: ai_session,
        params: {
          role: :assistant,
          message_type: :hint,
          content: normalize_assistant_content(starting_message_content(prompt)),
          metadata: {
            "provider" => "policy",
            "policy" => "starting_hint",
            "generated_for_message_id" => user_message.id,
            "assignment_id" => ai_session.assignment_id,
            "submission_id" => ai_session.submission_id,
            "assignment_step_id" => prompt.dig(:assignment_step, :id)
          }.compact
        }
      ).call

      return Result.new(success?: true, message: result.message, errors: []) if result.success?

      Result.new(success?: false, message: result.message, errors: result.errors)
    end

    def policy_message_content
      "Не можам да ти дадам готови извори, линкови или презентација. Користи учебник, белешки и материјали од час. Ако сакаш, кажи ја темата и ќе ти помогнам сам да одлучиш што да истражиш и како да го објасниш."
    end

    def starting_message_content(prompt)
      step_label = prompt.dig(:assignment_step, :prompt).presence ||
                   prompt.dig(:assignment_step, :title).presence ||
                   prompt.dig(:assignment_step, :content).presence

      if step_label.present?
        "Почни од чекорот: #{step_label}. Раздели го на една мала акција и кажи ми што би направил прво."
      else
        "Почни со тоа што ќе го прочиташ барањето и ќе го поделиш на мали чекори. Кој би бил твојот прв чекор?"
      end
    end

    def normalize_assistant_content(content)
      words = content.to_s.strip.split(/\s+/)
      return content.to_s.strip if words.length <= MAX_RESPONSE_WORDS

      "#{words.first(MAX_RESPONSE_WORDS).join(' ')}..."
    end

    def matches_any?(text, patterns)
      patterns.any? { |pattern| text.match?(pattern) }
    end

    def append_fallback_error_message(error)
      AiMessages::Append.new(
        ai_session: ai_session,
        params: {
          role: :assistant,
          message_type: :error,
          content: normalize_assistant_content("Моментално не можам да одговорам. Кажи ми што проба досега и ќе продолжиме чекор по чекор."),
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
