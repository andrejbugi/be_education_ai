require "test_helper"

class Api::V1::AiSessionsFlowTest < ActionDispatch::IntegrationTest
  test "student can create message and close ai session" do
    student_role = Role.create!(name: "student")

    school = School.create!(name: "ОУ Димитар Миладинов", code: "OU-DM")
    student = User.create!(email: "ai.student@example.com", password: "password123", password_confirmation: "password123")
    UserRole.create!(user: student, role: student_role)
    SchoolUser.create!(school: school, user: student)

    headers = auth_headers_for(student, school: school)

    post "/api/v1/ai_sessions", params: {
      title: "Помош по математика",
      session_type: "practice",
      context_data: { topic: "дробки" }
    }, headers: headers
    assert_response :created
    session_payload = JSON.parse(response.body)

    post "/api/v1/ai_sessions/#{session_payload['id']}/messages", params: {
      role: "user",
      message_type: "question",
      content: "Како се собираат дробки?"
    }, headers: headers
    assert_response :created
    message_payload = JSON.parse(response.body)
    assert_equal 1, message_payload["sequence_number"]

    get "/api/v1/ai_sessions/#{session_payload['id']}", headers: headers
    assert_response :success
    reloaded = JSON.parse(response.body)
    assert_equal 1, reloaded["messages"].length

    post "/api/v1/ai_sessions/#{session_payload['id']}/close", headers: headers
    assert_response :success
    closed = JSON.parse(response.body)
    assert_equal "completed", closed["status"]
  end
end
