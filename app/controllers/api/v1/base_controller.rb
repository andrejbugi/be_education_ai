module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_user!

      attr_reader :current_user
      attr_reader :current_auth_session

      private

      def authenticate_user!
        @current_auth_session = resolve_auth_session_from_cookie
        @current_user = @current_auth_session&.user
        return if @current_user&.active?

        render_unauthorized unless @current_user
      end

      def current_school
        school_id = request.headers["X-School-Id"].presence || params[:school_id] || current_auth_session&.current_school_id
        return nil if school_id.blank?

        current_user.schools.find_by(id: school_id)
      end

      def set_auth_session_cookie(raw_token, expires_at:)
        cookies.encrypted[auth_session_cookie_name] = {
          value: raw_token,
          httponly: true,
          same_site: :lax,
          secure: secure_auth_cookies?,
          expires: expires_at
        }
      end

      def clear_auth_session_cookie
        cookies.delete(
          auth_session_cookie_name,
          httponly: true,
          same_site: :lax,
          secure: secure_auth_cookies?
        )
      end

      def auth_session_cookie_name
        :be_education_ai_auth_session
      end

      def secure_auth_cookies?
        Rails.env.production?
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

      def resolve_auth_session_from_cookie
        auth_session = Auth::Sessions::Resolve.new(raw_token: raw_auth_session_token).call
        return nil unless auth_session&.user&.active?

        if auth_session.last_seen_at.nil? || auth_session.last_seen_at < 10.minutes.ago
          auth_session.update_column(:last_seen_at, Time.current)
        end

        auth_session
      end

      def raw_auth_session_token
        cookies.encrypted[auth_session_cookie_name].presence || test_auth_session_token
      end

      def test_auth_session_token
        return nil unless Rails.env.test?

        request.headers["X-Test-Auth-Session"].presence
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
