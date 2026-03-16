module Api
  module V1
    class MessageReactionsController < BaseController
      include ChatSerialization

      before_action :set_message

      def create
        result = MessageReactions::Create.new(message: @message, user: current_user, reaction: reaction_param).call

        if result.success?
          render json: serialize_message(reload_message), status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      def destroy
        result = MessageReactions::Destroy.new(message: @message, user: current_user, reaction: reaction_param).call

        if result.success?
          render json: serialize_message(reload_message)
        else
          render json: { errors: result.errors }, status: :not_found
        end
      end

      private

      def set_message
        @message = accessible_messages.find_by(id: params[:id])
        render_not_found unless @message
      end

      def accessible_messages
        Message.joins(conversation: :conversation_participants)
          .where(conversation_participants: { user_id: current_user.id, active: true })
          .distinct
      end

      def reload_message
        accessible_messages.includes(
          :sender,
          :message_reactions,
          :message_deliveries,
          :message_reads,
          { message_attachments: { file_attachment: :blob } }
        ).find(@message.id)
      end

      def reaction_param
        params[:reaction].to_s
      end
    end
  end
end
