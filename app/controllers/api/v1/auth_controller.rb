module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: :login

      def login
        user = User.find_by(email: login_params[:email]&.downcase)
        return render_invalid_credentials unless user&.authenticate(login_params[:password])
        return render_invalid_credentials unless user.active?

        school = resolve_school_for(user)
        if login_params[:school_id].present? && school.nil?
          return render json: { error: "School context is invalid" }, status: :forbidden
        end

        session_result = Auth::Sessions::Create.new(user: user, school: school, request: request).call
        return render json: { errors: session_result.errors }, status: :unprocessable_entity unless session_result.success?

        set_auth_session_cookie(session_result.raw_token, expires_at: session_result.auth_session.expires_at)

        render json: {
          user: user_payload(user),
          school: school_payload(school),
          session_expires_at: session_result.auth_session.expires_at
        }
      end

      def logout
        Auth::Sessions::Revoke.new(auth_session: current_auth_session).call if current_auth_session
        clear_auth_session_cookie
        head :no_content
      end

      def me
        render json: {
          user: user_payload(current_user),
          schools: current_user.schools.select(:id, :name, :code),
          current_school: school_payload(current_school),
          session_authenticated: current_auth_session.present?,
          session_expires_at: current_auth_session&.expires_at
        }
      end

      private

      def login_params
        wrapped_params = params[:auth]
        auth_params = wrapped_params.is_a?(ActionController::Parameters) ? wrapped_params : params
        auth_params.permit(:email, :password, :school_id)
      end

      def resolve_school_for(user)
        return nil unless user.schools.exists?

        if login_params[:school_id].present?
          user.schools.find_by(id: login_params[:school_id])
        else
          user.schools.order(:name).first
        end
      end

      def user_payload(user)
        {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          full_name: user.full_name,
          roles: user.roles.pluck(:name)
        }
      end

      def school_payload(school)
        return nil unless school

        {
          id: school.id,
          name: school.name,
          code: school.code
        }
      end

      def render_invalid_credentials
        render json: { error: "Invalid credentials" }, status: :unauthorized
      end
    end
  end
end
