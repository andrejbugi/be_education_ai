module Messages
  class MarkRead
    Result = Struct.new(:success?, :message, :errors, keyword_init: true)

    def initialize(message:, user:)
      @message = message
      @user = user
    end

    def call
      return failure(["Only active participants can mark messages as read"]) unless participant

      timestamp = Time.current

      Message.transaction do
        delivery = message.message_deliveries.find_or_initialize_by(user: user)
        delivery.delivered_at = timestamp
        delivery.save!

        read = message.message_reads.find_or_initialize_by(user: user)
        read.read_at = timestamp
        read.save!

        update_participant!(timestamp)
        message.refresh_status!
      end

      Result.new(success?: true, message: message, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :message, :user

    def participant
      @participant ||= message.conversation.conversation_participants.active.find_by(user_id: user.id)
    end

    def update_participant!(timestamp)
      return participant.update!(last_read_at: timestamp) if participant.last_read_message_id.present? && participant.last_read_message_id > message.id

      participant.update!(
        last_read_message: message,
        last_read_at: timestamp
      )
    end

    def failure(errors)
      Result.new(success?: false, message: message, errors: Array(errors))
    end
  end
end
