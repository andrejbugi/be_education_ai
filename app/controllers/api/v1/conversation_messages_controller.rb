module Api
  module V1
    class ConversationMessagesController < BaseController
      include ChatSerialization

      before_action :set_conversation

      def index
        limit, offset = pagination_params
        messages = @conversation.messages.visible
          .includes(
            :sender,
            :message_reactions,
            :message_deliveries,
            :message_reads,
            { message_attachments: { file_attachment: :blob } }
          )
          .limit(limit)
          .offset(offset)

        render json: messages.map { |message| serialize_message(message) }
      end

      def create
        result = Messages::Create.new(
          conversation: @conversation,
          sender: current_user,
          params: message_params.to_h.symbolize_keys
        ).call

        if result.success?
          log_activity(
            action: "conversation_message_created",
            trackable: result.message,
            metadata: { conversation_id: @conversation.id, message_id: result.message.id }
          )

          render json: serialize_message(reload_message(result.message)), status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def set_conversation
        @conversation = accessible_conversations.find_by(id: params[:conversation_id])
        render_not_found unless @conversation
      end

      def accessible_conversations
        participant_conversation_ids = ConversationParticipant.active.where(user_id: current_user.id).select(:conversation_id)

        Conversation.where(id: participant_conversation_ids)
          .where(conversations: { active: true })
      end

      def reload_message(message)
        @conversation.messages.includes(
          :sender,
          :message_reactions,
          :message_deliveries,
          :message_reads,
          { message_attachments: { file_attachment: :blob } }
        ).find(message.id)
      end

      def message_params
        params.permit(:body, :message_type, :reply_to_message_id, files: [])
      end
    end
  end
end
