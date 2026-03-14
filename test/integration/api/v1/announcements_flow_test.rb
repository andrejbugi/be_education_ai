require "test_helper"

class Api::V1::AnnouncementsFlowTest < ActionDispatch::IntegrationTest
  test "teacher can create and publish announcement and student can read it" do
    teacher_role = Role.create!(name: "teacher")
    student_role = Role.create!(name: "student")

    school = School.create!(name: "ОУ Гоце Делчев", code: "OU-GD")
    teacher = User.create!(email: "announce.teacher@example.com", password: "password123", password_confirmation: "password123")
    student = User.create!(email: "announce.student@example.com", password: "password123", password_confirmation: "password123")

    UserRole.create!(user: teacher, role: teacher_role)
    UserRole.create!(user: student, role: student_role)
    SchoolUser.create!(school: school, user: teacher)
    SchoolUser.create!(school: school, user: student)

    classroom = Classroom.create!(school: school, name: "7-A", grade_level: "7")
    TeacherClassroom.create!(classroom: classroom, user: teacher)
    ClassroomUser.create!(classroom: classroom, user: student)

    teacher_headers = auth_headers_for(teacher, school: school)
    student_headers = auth_headers_for(student, school: school)

    post "/api/v1/announcements", params: {
      classroom_id: classroom.id,
      title: "Важно известување",
      body: "Утре донесете тетратки.",
      audience_type: "classroom",
      priority: "important"
    }, headers: teacher_headers

    assert_response :created
    announcement_id = JSON.parse(response.body)["id"]

    post "/api/v1/announcements/#{announcement_id}/publish", headers: teacher_headers
    assert_response :success

    get "/api/v1/announcements", headers: student_headers
    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal 1, payload.length
    assert_equal "Важно известување", payload.first["title"]

    get "/api/v1/notifications", headers: student_headers
    assert_response :success
    notifications = JSON.parse(response.body)
    assert_equal 1, notifications["unread_count"]
  end
end
