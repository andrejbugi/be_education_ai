module ChatRealtime
  class BroadcastMessageCreated
    def initialize(message:, payload:)
      @message = message
      @payload = payload
    end

    def call
      ConversationChannel.broadcast_to(
        message.conversation,
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
