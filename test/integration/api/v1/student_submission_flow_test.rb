require "test_helper"

class Api::V1::StudentSubmissionFlowTest < ActionDispatch::IntegrationTest
  test "student can start update and submit submission" do
    teacher_role = Role.create!(name: "teacher")
    student_role = Role.create!(name: "student")

    school = School.create!(name: "ОУ Браќа Миладиновци", code: "OU-BM")

    teacher = User.create!(email: "teacher@example.com", password: "password123", password_confirmation: "password123")
    student = User.create!(email: "student2@example.com", password: "password123", password_confirmation: "password123")

    UserRole.create!(user: teacher, role: teacher_role)
    UserRole.create!(user: student, role: student_role)

    SchoolUser.create!(school: school, user: teacher)
    SchoolUser.create!(school: school, user: student)

    classroom = Classroom.create!(school: school, name: "7-A", grade_level: "7")
    ClassroomUser.create!(classroom: classroom, user: student)
    TeacherClassroom.create!(classroom: classroom, user: teacher)

    subject = Subject.create!(school: school, name: "Математика")
    TeacherSubject.create!(teacher: teacher, subject: subject)

    assignment = Assignment.create!(
      classroom: classroom,
      subject: subject,
      teacher: teacher,
      title: "Задача 1",
      status: :published,
      due_at: 2.days.from_now
    )
    step = AssignmentStep.create!(assignment: assignment, position: 1, title: "Чекор 1", content: "Реши")

    headers = auth_headers_for(student, school: school)

    post "/api/v1/assignments/#{assignment.id}/submissions", headers: headers
    assert_response :created

    submission_id = JSON.parse(response.body)["id"]

    patch "/api/v1/submissions/#{submission_id}", params: {
      step_answers: [
        {
          assignment_step_id: step.id,
          answer_text: "42"
        }
      ]
    }, headers: headers

    assert_response :success
    updated = JSON.parse(response.body)
    assert_equal "in_progress", updated["status"]

    post "/api/v1/submissions/#{submission_id}/submit", headers: headers
    assert_response :success
    submitted = JSON.parse(response.body)
    assert_includes ["submitted", "late"], submitted["status"]
  end
end
