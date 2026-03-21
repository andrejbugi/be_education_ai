module Admin
  module Invitations
    class Resend
      Result = Struct.new(:success?, :invitation, :raw_token, :errors, keyword_init: true)
      INVITATION_EXPIRY = 7.days

      def initialize(invitation:)
        @invitation = invitation
      end

      def call
        return Result.new(success?: false, invitation: invitation, raw_token: nil, errors: ["Invitation has already been accepted"]) if invitation.accepted?

        raw_token = SecureRandom.urlsafe_base64(32)

        invitation.update!(
          status: :pending,
          token_digest: UserInvitation.digest(raw_token),
          expires_at: INVITATION_EXPIRY.from_now,
          last_sent_at: Time.current
        )

        UserInvitationMailer.invitation_email(invitation.id, raw_token).deliver_now
        Result.new(success?: true, invitation: invitation, raw_token: raw_token, errors: [])
      rescue ActiveRecord::RecordInvalid => e
        Result.new(success?: false, invitation: invitation, raw_token: nil, errors: e.record.errors.full_messages)
      end

      private

      attr_reader :invitation
    end
  end
end
