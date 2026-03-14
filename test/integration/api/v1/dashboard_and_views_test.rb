require "test_helper"

class Api::V1::DashboardAndViewsTest < ActionDispatch::IntegrationTest
  test "teacher dashboard returns review queue homerooms and upcoming events" do
    school = create_school
    teacher = create_teacher(school: school, first_name: "Ана")
    classroom = create_classroom(school: school, teacher: teacher, name: "7-A")
    subject = create_subject(school: school, teacher: teacher, name: "Математика")
    student = create_student(school: school, classroom: classroom, first_name: "Марија")
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher)
    create_submission(assignment: assignment, student: student, status: :submitted)
    HomeroomAssignment.create!(school: school, classroom: classroom, teacher: teacher, starts_on: Date.current)
    CalendarEvent.create!(school: school, title: "Настан", starts_at: 1.day.from_now)

    get "/api/v1/teacher/dashboard", headers: auth_headers_for(teacher, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal 1, payload["review_queue"].length
    assert_equal 1, payload["homerooms"].length
    assert_equal 1, payload["upcoming_calendar_events"].length
  end

  test "student dashboard returns announcements performance snapshot and ai resume" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom)
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher)
    create_submission(assignment: assignment, student: student, status: :in_progress, submitted_at: nil)
    Announcement.create!(school: school, author: teacher, classroom: classroom, title: "Известување", body: "Текст", audience_type: "classroom", status: :published, priority: :important, published_at: Time.current)
    AttendanceRecord.create!(school: school, classroom: classroom, subject: subject, student: student, teacher: teacher, attendance_date: Date.current, status: :present)
    AiSession.create!(school: school, user: student, subject: subject, title: "AI", session_type: :practice, status: :active, started_at: 1.hour.ago, last_activity_at: Time.current, context_data: {})

    get "/api/v1/student/dashboard", headers: auth_headers_for(student, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal 1, payload["announcements"].length
    assert_not_nil payload["performance_snapshot"]
    assert_not_nil payload["ai_resume"]
  end

  test "teacher classrooms index only returns classrooms taught by teacher" do
    school = create_school
    teacher = create_teacher(school: school)
    other_teacher = create_teacher(school: school)
    taught = create_classroom(school: school, teacher: teacher, name: "7-A")
    create_classroom(school: school, teacher: other_teacher, name: "7-B")

    get "/api/v1/teacher/classrooms", headers: auth_headers_for(teacher, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal [taught.id], payload.map { |item| item["id"] }
  end

  test "teacher classroom show includes students and assignments" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    create_student(school: school, classroom: classroom)
    create_assignment(classroom: classroom, subject: subject, teacher: teacher)

    get "/api/v1/teacher/classrooms/#{classroom.id}", headers: auth_headers_for(teacher, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal 1, payload["students"].length
    assert_equal 1, payload["assignments"].length
  end

  test "teacher subjects index only returns assigned subjects" do
    school = create_school
    teacher = create_teacher(school: school)
    other_teacher = create_teacher(school: school)
    subject = create_subject(school: school, teacher: teacher, name: "Историја")
    create_subject(school: school, teacher: other_teacher, name: "Физика")

    get "/api/v1/teacher/subjects", headers: auth_headers_for(teacher, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal [subject.id], payload.map { |item| item["id"] }
  end

  test "teacher student show returns student details for shared classroom" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom, first_name: "Иван")

    get "/api/v1/teacher/students/#{student.id}", headers: auth_headers_for(teacher, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal student.id, payload["student"]["id"]
  end

  test "teacher student show forbids unrelated teacher" do
    school = create_school
    teacher = create_teacher(school: school)
    other_teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom)

    get "/api/v1/teacher/students/#{student.id}", headers: auth_headers_for(other_teacher, school: school)

    assert_response :forbidden
  end

  test "student assignments index excludes draft assignments" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom)
    published_assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher, status: :published)
    create_assignment(classroom: classroom, subject: subject, teacher: teacher, status: :draft)

    get "/api/v1/student/assignments", headers: auth_headers_for(student, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal [published_assignment.id], payload.map { |item| item["id"] }
  end

  test "student assignment show includes steps and submission" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom)
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher)
    create_assignment_step(assignment: assignment)
    submission = create_submission(assignment: assignment, student: student, status: :submitted)

    get "/api/v1/student/assignments/#{assignment.id}", headers: auth_headers_for(student, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal 1, payload["steps"].length
    assert_equal submission.id, payload["submission"]["id"]
  end
end
