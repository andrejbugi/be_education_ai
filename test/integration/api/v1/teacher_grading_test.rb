require "test_helper"

class Api::V1::TeacherGradingTest < ActionDispatch::IntegrationTest
  test "teacher can grade student submission" do
    teacher_role = Role.create!(name: "teacher")
    student_role = Role.create!(name: "student")

    school = School.create!(name: "ОУ Кочо Рацин", code: "OU-KR")

    teacher = User.create!(email: "teacher2@example.com", password: "password123", password_confirmation: "password123")
    student = User.create!(email: "student3@example.com", password: "password123", password_confirmation: "password123")

    UserRole.create!(user: teacher, role: teacher_role)
    UserRole.create!(user: student, role: student_role)

    SchoolUser.create!(school: school, user: teacher)
    SchoolUser.create!(school: school, user: student)

    classroom = Classroom.create!(school: school, name: "8-B", grade_level: "8")
    ClassroomUser.create!(classroom: classroom, user: student)

    subject = Subject.create!(school: school, name: "Биологија")

    assignment = Assignment.create!(
      classroom: classroom,
      subject: subject,
      teacher: teacher,
      title: "Клетка",
      status: :published
    )

    submission = Submission.create!(
      assignment: assignment,
      student: student,
      status: :submitted,
      submitted_at: Time.current
    )

    headers = auth_headers_for(teacher, school: school)

    post "/api/v1/submissions/#{submission.id}/grades", params: {
      score: 88,
      max_score: 100,
      feedback: "Одлично"
    }, headers: headers

    assert_response :created
    payload = JSON.parse(response.body)
    assert_equal submission.id, payload["submission_id"]
    assert_equal 88.0, payload["score"].to_f

    submission.reload
    assert_equal "reviewed", submission.status
  end
end
