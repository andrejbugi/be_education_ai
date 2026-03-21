class UserInvitationMailer < ApplicationMailer
  def invitation_email(invitation_id, raw_token)
    @invitation = UserInvitation.includes(:school, :user).find(invitation_id)
    @raw_token = raw_token
    @accept_url = api_v1_invitation_url(@raw_token)
    @accept_endpoint = accept_api_v1_invitation_url(@raw_token)

    mail(
      to: @invitation.user.email,
      subject: "#{@invitation.school.name}: Покана за #{@invitation.role_name == 'teacher' ? 'наставник' : 'ученик'}"
    )
  end
end
