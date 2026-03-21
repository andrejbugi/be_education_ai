require "test_helper"

class Api::V1::AuthTest < ActionDispatch::IntegrationTest
  test "login sets a cookie-backed session and me returns current user without bearer header" do
    role = Role.create!(name: "student")
    school = School.create!(name: "ОУ Климент", code: "OU-KL")
    user = User.create!(
      email: "student@example.com",
      password: "password123",
      password_confirmation: "password123",
      first_name: "Јана",
      last_name: "Петровска"
    )
    UserRole.create!(user: user, role: role)
    SchoolUser.create!(school: school, user: user)

    post "/api/v1/auth/login", params: {
      email: user.email,
      password: "password123",
      school_id: school.id
    }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal user.id, body.dig("user", "id")
    assert body["session_expires_at"].present?
    assert_not_nil cookies[:be_education_ai_auth_session]
    assert_equal 1, AuthSession.where(user: user, revoked_at: nil).count

    get "/api/v1/auth/me"
    assert_response :success

    me = JSON.parse(response.body)
    assert_equal user.id, me.dig("user", "id")
    assert_equal true, me["session_authenticated"]
    assert_equal school.id, me.dig("current_school", "id")
  end

  test "logout revokes the current cookie-backed session" do
    school = create_school(code: "AUTH-LOGOUT")
    user = create_teacher(school: school, email: "logout.teacher@example.com")

    post "/api/v1/auth/login", params: {
      email: user.email,
      password: "password123",
      school_id: school.id
    }

    assert_response :success
    auth_session = AuthSession.order(:id).last
    assert_nil auth_session.revoked_at

    delete "/api/v1/auth/logout"

    assert_response :no_content
    assert auth_session.reload.revoked_at.present?

    get "/api/v1/auth/me"
    assert_response :unauthorized
  end

  test "login accepts wrapped auth payload" do
    role = Role.create!(name: "student")
    school = School.create!(name: "ОУ Климент", code: "OU-KL-2")
    user = User.create!(
      email: "student-wrapped@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    UserRole.create!(user: user, role: role)
    SchoolUser.create!(school: school, user: user)

    post "/api/v1/auth/login", params: {
      auth: {
        email: user.email,
        password: "password123",
        school_id: school.id
      }
    }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal user.id, body.dig("user", "id")
    assert_equal school.id, body.dig("school", "id")
  end
end
