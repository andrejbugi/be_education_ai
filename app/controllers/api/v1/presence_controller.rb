module Api
  module V1
    class PresenceController < BaseController
      def update
        result = UserPresenceStatuses::Update.new(user: current_user, params: presence_params.to_h.symbolize_keys).call

        if result.success?
          render json: {
            user_id: result.presence_status.user_id,
            status: result.presence_status.status,
            last_seen_at: result.presence_status.last_seen_at
          }
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def presence_params
        permitted = params.permit(:status, presence: [:status])
        status = permitted[:status].presence || permitted.dig(:presence, :status)

        ActionController::Parameters.new(status: status).permit(:status)
      end
    end
  end
end
