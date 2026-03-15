require "test_helper"

class Api::V1::TeacherGradingTest < ActionDispatch::IntegrationTest
  test "teacher can view submission details for grading" do
    school = create_school(name: "ОУ Кочо Рацин", code: "OU-KR-VIEW")
    teacher = create_teacher(school: school, email: "teacher-view@example.com")
    classroom = create_classroom(school: school, teacher: teacher, name: "8-B")
    subject = create_subject(school: school, teacher: teacher, name: "Биологија")
    student = create_student(school: school, classroom: classroom, email: "student-view@example.com")
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher, title: "Клетка", status: :published)
    step = create_assignment_step(
      assignment: assignment,
      position: 1,
      title: "Чекор 1",
      evaluation_mode: "normalized_text",
      answer_keys: [{ value: "x=5" }]
    )
    submission = create_submission(assignment: assignment, student: student, status: :submitted, submitted_at: Time.current)
    SubmissionStepAnswer.create!(
      submission: submission,
      assignment_step: step,
      answer_text: "x = 5",
      answer_data: {},
      status: :correct,
      answered_at: Time.current
    )
    grade = create_grade(submission: submission, teacher: teacher, score: 88, max_score: 100, feedback: "Одлично")

    get "/api/v1/teacher/submissions/#{submission.id}", headers: auth_headers_for(teacher, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal submission.id, payload["id"]
    assert_equal student.id, payload.dig("student", "id")
    assert_equal assignment.id, payload.dig("assignment", "id")
    assert_equal 1, payload["steps"].length
    assert_equal "x=5", payload.dig("steps", 0, "answer_keys", 0, "value")
    assert_equal 1, payload["step_answers"].length
    assert_equal "x = 5", payload.dig("step_answers", 0, "answer_text")
    assert_equal grade.id, payload.dig("grade", "id")
  end

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

  test "unrelated teacher cannot view submission details for grading" do
    school = create_school(name: "ОУ Кочо Рацин", code: "OU-KR-FORBID")
    teacher = create_teacher(school: school, email: "teacher-main@example.com")
    other_teacher = create_teacher(school: school, email: "teacher-other@example.com")
    classroom = create_classroom(school: school, teacher: teacher, name: "8-B")
    subject = create_subject(school: school, teacher: teacher, name: "Биологија")
    student = create_student(school: school, classroom: classroom, email: "student-forbid@example.com")
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher, title: "Клетка", status: :published)
    submission = create_submission(assignment: assignment, student: student, status: :submitted, submitted_at: Time.current)

    get "/api/v1/teacher/submissions/#{submission.id}", headers: auth_headers_for(other_teacher, school: school)

    assert_response :forbidden
  end
end
