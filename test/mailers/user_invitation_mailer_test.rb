require "test_helper"

class UserInvitationMailerTest < ActionMailer::TestCase
  test "invitation email includes access links and school details" do
    school = create_school(name: "ОУ Тест", code: "TEST")
    admin = create_admin(school: school, email: "admin.mailer@example.com")
    user = create_user_with_roles(school: school, roles: %w[teacher], email: "teacher.mailer@example.com", active: false)
    invitation, raw_token = create_user_invitation(user: user, school: school, invited_by: admin, role_name: "teacher")

    email = UserInvitationMailer.invitation_email(invitation.id, raw_token)
    text_body = email.text_part.body.decoded
    html_body = email.html_part.body.decoded

    assert_equal ["teacher.mailer@example.com"], email.to
    assert_includes email.subject, "ОУ Тест"
    assert_includes text_body, raw_token
    assert_includes html_body, raw_token
    assert_includes text_body, "/api/v1/invitations/#{raw_token}"
    assert_includes text_body, "/api/v1/invitations/#{raw_token}/accept"
  end
end
