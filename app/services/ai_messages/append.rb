module AiMessages
  class Append
    Result = Struct.new(:success?, :message, :errors, keyword_init: true)

    def initialize(ai_session:, params:)
      @ai_session = ai_session
      @params = params
    end

    def call
      message = nil

      AiMessage.transaction do
        next_sequence = ai_session.ai_messages.maximum(:sequence_number).to_i + 1
        message = ai_session.ai_messages.create!(message_attributes.merge(sequence_number: next_sequence))
        ai_session.update!(last_activity_at: Time.current)
      end

      Result.new(success?: true, message: message, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, message: e.record, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :ai_session, :params

    def message_attributes
      params.slice(:role, :message_type, :content, :metadata)
    end
  end
end
