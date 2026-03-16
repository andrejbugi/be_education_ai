module Api
  module V1
    class MessageDeliveriesController < BaseController
      include ChatSerialization

      before_action :set_message

      def create
        result = Messages::MarkDelivered.new(message: @message, user: current_user).call

        if result.success?
          render json: serialize_message(reload_message)
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
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
    end
  end
end
