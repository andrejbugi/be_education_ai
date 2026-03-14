require "test_helper"

class Api::V1::Phase2EndpointsTest < ActionDispatch::IntegrationTest
  test "teacher homerooms index is scoped to active assignments" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    HomeroomAssignment.create!(school: school, classroom: classroom, teacher: teacher, starts_on: Date.current, active: true)

    get "/api/v1/teacher/homerooms", headers: auth_headers_for(teacher, school: school)

    assert_response :success
    assert_equal 1, JSON.parse(response.body).length
  end

  test "announcement draft is not visible to student index" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom)
    Announcement.create!(school: school, author: teacher, classroom: classroom, title: "Draft", body: "Body", audience_type: "classroom", status: :draft)

    get "/api/v1/announcements", headers: auth_headers_for(student, school: school)

    assert_response :success
    assert_equal [], JSON.parse(response.body)
  end

  test "teacher can archive announcement" do
    school = create_school
    teacher = create_teacher(school: school)
    announcement = Announcement.create!(school: school, author: teacher, title: "Title", body: "Body", audience_type: "school", status: :published, published_at: Time.current)

    post "/api/v1/announcements/#{announcement.id}/archive", headers: auth_headers_for(teacher, school: school)

    assert_response :success
    assert_equal "archived", announcement.reload.status
  end

  test "attendance index is scoped to student records" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom)
    other_student = create_student(school: school, classroom: classroom)
    AttendanceRecord.create!(school: school, classroom: classroom, subject: subject, student: student, teacher: teacher, attendance_date: Date.current, status: :present)
    AttendanceRecord.create!(school: school, classroom: classroom, subject: subject, student: other_student, teacher: teacher, attendance_date: Date.current, status: :absent)

    get "/api/v1/attendance_records", headers: auth_headers_for(student, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal [student.id], payload.map { |item| item["student"]["id"] }
  end

  test "classroom attendance is visible to classroom student" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom)
    AttendanceRecord.create!(school: school, classroom: classroom, subject: subject, student: student, teacher: teacher, attendance_date: Date.current, status: :present)

    get "/api/v1/classrooms/#{classroom.id}/attendance", headers: auth_headers_for(student, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal classroom.id, payload["classroom_id"]
    assert_equal 1, payload["records"].length
  end

  test "student attendance is forbidden to unrelated teacher" do
    school = create_school
    teacher = create_teacher(school: school)
    other_teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom)

    get "/api/v1/students/#{student.id}/attendance", headers: auth_headers_for(other_teacher, school: school)

    assert_response :forbidden
  end

  test "student performance endpoint returns snapshot payload" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom)
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher)
    submission = create_submission(assignment: assignment, student: student, status: :reviewed, reviewed_at: Time.current, total_score: 88)
    create_grade(submission: submission, teacher: teacher, score: 88)
    AttendanceRecord.create!(school: school, classroom: classroom, subject: subject, student: student, teacher: teacher, attendance_date: Date.current, status: :present)

    get "/api/v1/student/performance", headers: auth_headers_for(student, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal "monthly", payload["period_type"]
    assert_equal 1, payload["completed_assignments_count"]
  end

  test "teacher can list stored student performance snapshots" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom)
    StudentPerformanceSnapshot.create!(school: school, student: student, classroom: classroom, period_type: :monthly, period_start: Date.current.beginning_of_month, period_end: Date.current.end_of_month, generated_at: Time.current)

    get "/api/v1/students/#{student.id}/performance_snapshots", headers: auth_headers_for(teacher, school: school)

    assert_response :success
    assert_equal 1, JSON.parse(response.body).length
  end

  test "ai sessions index is scoped to current user" do
    school = create_school
    student = create_student(school: school)
    other_student = create_student(school: school)
    AiSession.create!(school: school, user: student, title: "Mine", session_type: :practice, status: :active, started_at: 1.hour.ago, last_activity_at: Time.current, context_data: {})
    AiSession.create!(school: school, user: other_student, title: "Other", session_type: :practice, status: :active, started_at: 1.hour.ago, last_activity_at: Time.current, context_data: {})

    get "/api/v1/ai_sessions", headers: auth_headers_for(student, school: school)

    assert_response :success
    assert_equal ["Mine"], JSON.parse(response.body).map { |item| item["title"] }
  end

  test "ai session show includes ordered messages" do
    school = create_school
    student = create_student(school: school)
    session = AiSession.create!(school: school, user: student, title: "AI", session_type: :practice, status: :active, started_at: 1.hour.ago, last_activity_at: Time.current, context_data: {})
    AiMessage.create!(ai_session: session, role: :user, message_type: :question, content: "Q1", sequence_number: 1)
    AiMessage.create!(ai_session: session, role: :assistant, message_type: :hint, content: "A1", sequence_number: 2)

    get "/api/v1/ai_sessions/#{session.id}", headers: auth_headers_for(student, school: school)

    assert_response :success
    payload = JSON.parse(response.body)
    assert_equal [1, 2], payload["messages"].map { |item| item["sequence_number"] }
  end

  test "ai messages index returns session messages" do
    school = create_school
    student = create_student(school: school)
    session = AiSession.create!(school: school, user: student, title: "AI", session_type: :practice, status: :active, started_at: 1.hour.ago, last_activity_at: Time.current, context_data: {})
    AiMessage.create!(ai_session: session, role: :user, message_type: :question, content: "Q1", sequence_number: 1)

    get "/api/v1/ai_sessions/#{session.id}/messages", headers: auth_headers_for(student, school: school)

    assert_response :success
    assert_equal 1, JSON.parse(response.body).length
  end

  test "ai session update changes status and title" do
    school = create_school
    student = create_student(school: school)
    session = AiSession.create!(school: school, user: student, title: "AI", session_type: :practice, status: :active, started_at: 1.hour.ago, last_activity_at: Time.current, context_data: {})

    patch "/api/v1/ai_sessions/#{session.id}", params: { title: "Updated AI", status: "paused" }, headers: auth_headers_for(student, school: school)

    assert_response :success
    session.reload
    assert_equal "Updated AI", session.title
    assert_equal "paused", session.status
  end
end
