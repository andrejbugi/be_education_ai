require "test_helper"

class Api::V1::PasswordResetsFlowTest < ActionDispatch::IntegrationTest
  setup do
    ActionMailer::Base.deliveries.clear
  end

  test "password reset request sends mail for active user and remains generic for unknown email" do
    school = create_school
    user = create_teacher(school: school, email: "reset.teacher@example.com")

    post "/api/v1/password_resets", params: { email: user.email }

    assert_response :no_content
    assert_equal 1, ActionMailer::Base.deliveries.size

    post "/api/v1/password_resets", params: { email: "unknown@example.com" }

    assert_response :no_content
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  test "inactive user reset request stays generic and sends no email" do
    school = create_school
    user = create_teacher(school: school, email: "inactive.reset@example.com")
    user.update!(active: false)

    post "/api/v1/password_resets", params: { email: user.email }

    assert_response :no_content
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  test "show returns reset token state and confirm updates password and revokes sessions" do
    school = create_school
    user = create_teacher(school: school, email: "reset.confirm@example.com")
    auth_session, raw_auth_token = create_auth_session(user: user, school: school)

    post "/api/v1/password_resets", params: { email: user.email }

    assert_response :no_content
    token = extract_password_reset_token(ActionMailer::Base.deliveries.last)

    get "/api/v1/password_resets/#{token}"

    assert_response :success
    show_payload = JSON.parse(response.body)
    assert_equal "pending", show_payload["status"]
    assert_equal true, show_payload["confirm_allowed"]
    assert_equal user.email, show_payload["email"]

    post "/api/v1/password_resets/#{token}/confirm", params: {
      password: "new-password-123",
      password_confirmation: "new-password-123"
    }

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal "used", payload.dig("password_reset", "status")
    assert_equal false, payload.dig("password_reset", "confirm_allowed")
    assert_not_nil payload.dig("password_reset", "used_at")
    assert_equal user.email, payload.dig("user", "email")

    assert_not user.reload.authenticate("password123")
    assert user.authenticate("new-password-123")
    assert auth_session.reload.revoked_at.present?

    get "/api/v1/auth/me", headers: { "X-Test-Auth-Session" => raw_auth_token, "X-School-Id" => school.id }
    assert_response :unauthorized

    post "/api/v1/auth/login", params: { email: user.email, password: "password123", school_id: school.id }
    assert_response :unauthorized

    post "/api/v1/auth/login", params: { email: user.email, password: "new-password-123", school_id: school.id }
    assert_response :success
  end

  test "expired and reused reset tokens are rejected on confirm" do
    school = create_school
    user = create_teacher(school: school, email: "reset.expired@example.com")
    password_reset = PasswordReset.create!(
      user: user,
      token_digest: PasswordReset.digest("expired-token"),
      expires_at: 1.minute.ago,
      last_sent_at: 31.minutes.ago
    )

    get "/api/v1/password_resets/expired-token"

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal "expired", payload["status"]
    assert_equal false, payload["confirm_allowed"]

    post "/api/v1/password_resets/expired-token/confirm", params: {
      password: "new-password-123",
      password_confirmation: "new-password-123"
    }

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["errors"], "Password reset link has expired"

    password_reset.update!(token_digest: PasswordReset.digest("used-token"), expires_at: 30.minutes.from_now, used_at: Time.current)

    get "/api/v1/password_resets/used-token"

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal "used", payload["status"]
    assert_equal false, payload["confirm_allowed"]

    post "/api/v1/password_resets/used-token/confirm", params: {
      password: "new-password-123",
      password_confirmation: "new-password-123"
    }

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["errors"], "Password reset link has already been used"
  end
end
