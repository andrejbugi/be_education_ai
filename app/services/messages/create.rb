module Messages
  class Create
    Result = Struct.new(:success?, :message, :errors, keyword_init: true)

    def initialize(conversation:, sender:, params:)
      @conversation = conversation
      @sender = sender
      @params = params
    end

    def call
      return failure(["Only active participants can send messages"]) unless participant
      return failure(["Reply target must belong to the same conversation"]) unless valid_reply_target?

      message = conversation.messages.new(
        sender: sender,
        body: params[:body],
        message_type: resolved_message_type,
        status: "sent",
        reply_to_message_id: params[:reply_to_message_id]
      )

      uploaded_files.each do |uploaded_file|
        message.message_attachments.build(file: uploaded_file)
      end

      Message.transaction do
        message.save!
        mark_sender_state!(message)
        conversation.update!(last_message: message, last_message_at: message.created_at)
      end

      Result.new(success?: true, message: message, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :conversation, :sender, :params

    def participant
      @participant ||= conversation.conversation_participants.active.find_by(user_id: sender.id)
    end

    def uploaded_files
      Array(params[:files]).compact
    end

    def resolved_message_type
      explicit_type = params[:message_type].presence
      return explicit_type if explicit_type.present?
      return "image" if uploaded_files.any? && uploaded_files.all? { |file| file.content_type.to_s.start_with?("image/") }
      return "file" if uploaded_files.any?

      "text"
    end

    def valid_reply_target?
      reply_to_message_id = params[:reply_to_message_id]
      return true if reply_to_message_id.blank?

      conversation.messages.exists?(id: reply_to_message_id)
    end

    def mark_sender_state!(message)
      timestamp = Time.current

      delivery = message.message_deliveries.find_or_initialize_by(user: sender)
      delivery.delivered_at = timestamp
      delivery.save!

      read = message.message_reads.find_or_initialize_by(user: sender)
      read.read_at = timestamp
      read.save!

      participant.update!(
        last_read_message: message,
        last_read_at: timestamp
      )
    end

    def failure(errors)
      Result.new(success?: false, message: nil, errors: Array(errors))
    end
  end
end
