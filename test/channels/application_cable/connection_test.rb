require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  include ApiTestFactory

  test "connects with a valid token param" do
    school = create_school(code: "CABLE-CONNECT")
    user = create_teacher(school: school, email: "cable.teacher@example.com")
    token = Auth::JwtToken.encode({ user_id: user.id })

    connect params: { token: token }

    assert_equal user, connection.current_user
  end

  test "rejects connection without a valid token" do
    assert_reject_connection do
      connect params: { token: "invalid-token" }
    end
  end
end
