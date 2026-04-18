module Api
  module V1
    class PasswordResetsController < BaseController
      skip_before_action :authenticate_user!
      wrap_parameters false

      def create
        result = Auth::PasswordResets::Request.new(email: password_reset_request_params[:email]).call
        return render json: { errors: result.errors }, status: :unprocessable_entity unless result.success?

        head :no_content
      end

      def show
        password_reset = find_password_reset
        return render_not_found unless password_reset

        render json: serialize_password_reset(password_reset)
      end

      def confirm
        result = Auth::PasswordResets::Confirm.new(token: params[:token], params: password_reset_confirm_params.to_h.symbolize_keys).call

        if result.success?
          render json: {
            password_reset: serialize_password_reset(result.password_reset),
            user: {
              id: result.user.id,
              email: result.user.email,
              first_name: result.user.first_name,
              last_name: result.user.last_name,
              active: result.user.active
            }
          }
        else
          status = result.password_reset.nil? ? :not_found : :unprocessable_entity
          render json: { errors: result.errors }, status: status
        end
      end

      private

      def find_password_reset
        Auth::PasswordResets::Resolve.new(token: params[:token]).call
      end

      def password_reset_request_params
        params.except(:controller, :action).permit(:email)
      end

      def password_reset_confirm_params
        params.except(:token, :controller, :action).permit(:password, :password_confirmation)
      end

      def serialize_password_reset(password_reset)
        {
          email: password_reset.user.email,
          status: password_reset.effective_status,
          confirm_allowed: password_reset.confirm_allowed?,
          expires_at: password_reset.expires_at,
          used_at: password_reset.used_at
        }
      end
    end
  end
end
