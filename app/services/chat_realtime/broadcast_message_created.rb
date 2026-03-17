module ChatRealtime
  class BroadcastMessageCreated
    def initialize(message:, payload:)
      @message = message
      @payload = payload
    end

    def call
      ActionCable.server.broadcast(
        ChatRealtime::ConversationStream.name_for(message.conversation_id),
        {
          type: "message.created",
          conversation_id: message.conversation_id,
          message: payload
        }
      )
    end

    private

    attr_reader :message, :payload
  end
end
