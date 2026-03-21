module Admin
  module Invitations
    class Accept
      Result = Struct.new(:success?, :invitation, :user, :errors, keyword_init: true)

      def initialize(token:, params:)
        @token = token
        @params = params
      end

      def call
        invitation = UserInvitation.includes(:user).find_by(token_digest: UserInvitation.digest(token))
        return Result.new(success?: false, invitation: nil, user: nil, errors: ["Invitation not found"]) unless invitation

        invitation.mark_expired!
        return Result.new(success?: false, invitation: invitation, user: invitation.user, errors: ["Invitation has already been used"]) if invitation.accepted?
        return Result.new(success?: false, invitation: invitation, user: invitation.user, errors: ["Invitation has been revoked"]) if invitation.revoked?
        return Result.new(success?: false, invitation: invitation, user: invitation.user, errors: ["Invitation has expired"]) if invitation.expired?

        User.transaction do
          invitation.user.update!(
            first_name: params[:first_name].presence || invitation.user.first_name,
            last_name: params[:last_name].presence || invitation.user.last_name,
            locale: params[:locale].presence || invitation.user.locale,
            password: params[:password],
            password_confirmation: params[:password_confirmation],
            active: true
          )
          invitation.update!(status: :accepted, accepted_at: Time.current)
        end

        Result.new(success?: true, invitation: invitation, user: invitation.user, errors: [])
      rescue ActiveRecord::RecordInvalid => e
        Result.new(success?: false, invitation: invitation, user: invitation&.user, errors: e.record.errors.full_messages)
      end

      private

      attr_reader :token, :params
    end
  end
end
