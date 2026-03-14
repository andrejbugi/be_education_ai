module Api
  module V1
    class AiMessagesController < BaseController
      before_action :set_ai_session

      def index
        return render_forbidden unless owns_session?(@ai_session)

        render json: @ai_session.ai_messages.map do |message|
          {
            id: message.id,
            role: message.role,
            message_type: message.message_type,
            content: message.content,
            sequence_number: message.sequence_number,
            metadata: message.metadata,
            created_at: message.created_at
          }
        end
      end

      def create
        return render_forbidden unless owns_session?(@ai_session)

        result = AiMessages::Append.new(ai_session: @ai_session, params: ai_message_params.to_h.symbolize_keys).call
        if result.success?
          log_activity(action: "ai_message_appended", trackable: @ai_session, metadata: { ai_session_id: @ai_session.id, ai_message_id: result.message.id })
          render json: {
            id: result.message.id,
            role: result.message.role,
            message_type: result.message.message_type,
            content: result.message.content,
            sequence_number: result.message.sequence_number,
            metadata: result.message.metadata,
            created_at: result.message.created_at
          }, status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def set_ai_session
        @ai_session = AiSession.find_by(id: params[:ai_session_id])
        render_not_found unless @ai_session
      end

      def owns_session?(session)
        current_user.has_role?("admin") || session.user_id == current_user.id
      end

      def ai_message_params
        params.permit(:role, :message_type, :content, metadata: {})
      end
    end
  end
end
