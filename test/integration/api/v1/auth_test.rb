require "test_helper"

class Api::V1::AuthTest < ActionDispatch::IntegrationTest
  test "login returns token and me returns current user" do
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
    assert body["token"].present?
    assert_equal user.id, body.dig("user", "id")

    get "/api/v1/auth/me", headers: { "Authorization" => "Bearer #{body['token']}" }
    assert_response :success

    me = JSON.parse(response.body)
    assert_equal user.id, me.dig("user", "id")
  end
end
