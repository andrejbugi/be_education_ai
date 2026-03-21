class UserInvitationMailer < ApplicationMailer
  def invitation_email(invitation_id, raw_token)
    @invitation = UserInvitation.includes(:school, :user).find(invitation_id)
    @raw_token = raw_token
    @accept_url = "#{frontend_base_url}/invitations/#{ERB::Util.url_encode(@raw_token)}"

    mail(
      to: @invitation.user.email,
      subject: "#{@invitation.school.name}: Покана за #{@invitation.role_name == 'teacher' ? 'наставник' : 'ученик'}"
    )
  end

  private

  def frontend_base_url
    ENV.fetch("FRONTEND_APP_URL", "http://localhost:3000").sub(%r{/\z}, "")
  end
end
