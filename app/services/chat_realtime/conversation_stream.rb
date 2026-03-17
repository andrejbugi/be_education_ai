module ChatRealtime
  module ConversationStream
    module_function

    def name_for(conversation_or_id)
      conversation_id = conversation_or_id.respond_to?(:id) ? conversation_or_id.id : conversation_or_id
      "conversation:#{conversation_id}"
    end
  end
end
