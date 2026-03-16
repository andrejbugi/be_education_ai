module Api
  module V1
    class ConversationsController < BaseController
      include ChatSerialization

      def index
        limit, offset = pagination_params
        conversations = accessible_conversations.limit(limit).offset(offset)

        render json: conversations.map { |conversation| serialize_conversation(conversation) }
      end

      def create
        school = current_school
        return render_not_found unless school

        result = Conversations::Create.new(
          current_user: current_user,
          school: school,
          params: conversation_params.to_h.symbolize_keys
        ).call

        if result.success?
          log_activity(
            action: "conversation_created",
            trackable: result.conversation,
            metadata: { conversation_id: result.conversation.id, created: result.created }
          ) if result.created

          render json: serialize_conversation(reload_conversation(result.conversation)), status: (result.created ? :created : :ok)
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def accessible_conversations
        participant_conversation_ids = ConversationParticipant.active.where(user_id: current_user.id).select(:conversation_id)

        scope = Conversation.where(id: participant_conversation_ids)
          .where(conversations: { active: true })
          .recent_first

        scope = scope.where(conversations: { school_id: current_school.id }) if current_school

        scope.includes(
          :conversation_participants,
          active_conversation_participants: { user: %i[roles user_presence_status] },
          last_message: [
            :sender,
            :message_reactions,
            :message_deliveries,
            :message_reads,
            { message_attachments: { file_attachment: :blob } }
          ]
        )
      end

      def reload_conversation(conversation)
        accessible_conversations.find(conversation.id)
      end

      def conversation_params
        params.permit(:school_id, :conversation_type, participant_ids: [])
      end
    end
  end
end
