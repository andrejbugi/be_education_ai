module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_user!

      attr_reader :current_user

      private

      def authenticate_user!
        token = bearer_token
        payload = token && Auth::JwtToken.decode(token)
        @current_user = payload && User.find_by(id: payload[:user_id], active: true)

        render_unauthorized unless @current_user
      end

      def bearer_token
        auth_header = request.headers["Authorization"].to_s
        return nil unless auth_header.start_with?("Bearer ")

        auth_header.split(" ", 2).last
      end

      def current_school
        school_id = request.headers["X-School-Id"].presence || params[:school_id]
        return nil if school_id.blank?

        current_user.schools.find_by(id: school_id)
      end

      def require_role!(*roles)
        return if current_user.has_any_role?(*roles)

        render_forbidden
      end

      def render_unauthorized
        render json: { error: "Unauthorized" }, status: :unauthorized
      end

      def render_forbidden
        render json: { error: "Forbidden" }, status: :forbidden
      end

      def render_not_found
        render json: { error: "Not found" }, status: :not_found
      end

      def pagination_params
        limit = params.fetch(:limit, 25).to_i
        offset = params.fetch(:offset, 0).to_i
        [limit.clamp(1, 100), [offset, 0].max]
      end

      def log_activity(action:, trackable: nil, metadata: {})
        current_user.activity_logs.create!(
          action: action,
          trackable: trackable,
          metadata: metadata,
          occurred_at: Time.current
        )
      end
    end
  end
end
