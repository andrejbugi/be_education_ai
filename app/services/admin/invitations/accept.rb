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
          accept_invitation!(invitation)
          invitation.update!(status: :accepted, accepted_at: Time.current)
        end

        Result.new(success?: true, invitation: invitation, user: invitation.user, errors: [])
      rescue ActiveRecord::RecordInvalid => e
        Result.new(success?: false, invitation: invitation, user: invitation&.user, errors: e.record.errors.full_messages)
      end

      private

      attr_reader :token, :params

      def accept_invitation!(invitation)
        user = invitation.user
        existing_active_user = user.active?

        user.assign_attributes(
          first_name: params[:first_name].presence || user.first_name,
          last_name: params[:last_name].presence || user.last_name,
          locale: params[:locale].presence || user.locale
        )

        apply_password!(user, existing_active_user: existing_active_user)
        user.active = true
        user.save!

        SchoolUser.find_or_create_by!(school: invitation.school, user: user)
        UserRole.find_or_create_by!(user: user, role: Role.find_by!(name: invitation.role_name))
      end

      def apply_password!(user, existing_active_user:)
        return if existing_active_user

        if params[:password].blank?
          user.errors.add(:password, "can't be blank")
          raise ActiveRecord::RecordInvalid.new(user)
        end

        user.password = params[:password]
        user.password_confirmation = params[:password_confirmation]
      end
    end
  end
end
