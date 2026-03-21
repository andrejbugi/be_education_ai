module Api
  module V1
    class InvitationsController < BaseController
      include AdminSerialization

      skip_before_action :authenticate_user!, only: %i[show accept]
      wrap_parameters false

      def show
        invitation = find_invitation
        return render_not_found unless invitation

        render json: serialize_public_invitation(invitation)
      end

      def accept
        result = ::Admin::Invitations::Accept.new(token: params[:token], params: invitation_accept_params.to_h.symbolize_keys).call

        if result.success?
          render json: {
            invitation: serialize_public_invitation(result.invitation),
            user: {
              id: result.user.id,
              email: result.user.email,
              first_name: result.user.first_name,
              last_name: result.user.last_name,
              active: result.user.active
            }
          }
        else
          status = result.invitation.nil? ? :not_found : :unprocessable_entity
          render json: { errors: result.errors }, status: status
        end
      end

      private

      def find_invitation
        invitation = UserInvitation.includes(:school, :user).find_by(token_digest: UserInvitation.digest(params[:token]))
        invitation&.mark_expired!
        invitation
      end

      def invitation_accept_params
        params.except(:token, :controller, :action).permit(
          :first_name,
          :last_name,
          :locale,
          :password,
          :password_confirmation
        )
      end
    end
  end
end
