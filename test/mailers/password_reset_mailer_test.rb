require "test_helper"

class PasswordResetMailerTest < ActionMailer::TestCase
  test "reset email includes reset link" do
    school = create_school(name: "ОУ Лозинка", code: "RESET")
    user = create_teacher(school: school, email: "teacher.reset.mailer@example.com")
    password_reset = PasswordReset.create!(
      user: user,
      token_digest: PasswordReset.digest("raw-reset-token"),
      expires_at: 30.minutes.from_now,
      last_sent_at: Time.current
    )

    email = PasswordResetMailer.reset_email(password_reset.id, "raw-reset-token")
    text_body = email.text_part.body.decoded
    html_body = email.html_part.body.decoded

    assert_equal ["teacher.reset.mailer@example.com"], email.to
    assert_includes email.subject, "Промена на лозинка"
    assert_includes text_body, "raw-reset-token"
    assert_includes html_body, "raw-reset-token"
    assert_includes text_body, "http://localhost:3000/reset-password/raw-reset-token"
    assert_includes html_body, "http://localhost:3000/reset-password/raw-reset-token"
  end
end
