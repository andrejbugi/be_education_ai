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

        token = Auth::JwtToken.encode(
          {
            user_id: user.id,
            school_id: school&.id,
            role_names: user.roles.pluck(:name)
          }
        )

        render json: {
          token: token,
          user: user_payload(user),
          school: school_payload(school)
        }
      end

      def logout
        # Stateless JWT logout for MVP. Client should discard token.
        head :no_content
      end

      def me
        render json: {
          user: user_payload(current_user),
          schools: current_user.schools.select(:id, :name, :code)
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
