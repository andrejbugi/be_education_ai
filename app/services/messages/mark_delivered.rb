module Messages
  class MarkDelivered
    Result = Struct.new(:success?, :message, :errors, keyword_init: true)

    def initialize(message:, user:)
      @message = message
      @user = user
    end

    def call
      return failure(["Only active participants can mark delivery"]) unless participant

      delivery = message.message_deliveries.find_or_initialize_by(user: user)
      delivery.delivered_at = Time.current
      delivery.save!

      message.refresh_status!

      Result.new(success?: true, message: message, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :message, :user

    def participant
      @participant ||= message.conversation.conversation_participants.active.find_by(user_id: user.id)
    end

    def failure(errors)
      Result.new(success?: false, message: message, errors: Array(errors))
    end
  end
end
