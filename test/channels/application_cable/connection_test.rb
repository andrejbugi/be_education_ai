require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  include ApiTestFactory

  test "connects with a valid cookie-backed auth session" do
    school = create_school(code: "CABLE-CONNECT")
    user = create_teacher(school: school, email: "cable.teacher@example.com")
    _, raw_token = create_auth_session(user: user, school: school)

    cookies.encrypted[:be_education_ai_auth_session] = raw_token
    connect

    assert_equal user, connection.current_user
  end

  test "rejects connection without a valid auth session cookie" do
    assert_reject_connection do
      connect
    end
  end
end
