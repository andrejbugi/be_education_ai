require "test_helper"

class Api::V1::AiSessionsFlowTest < ActionDispatch::IntegrationTest
  test "student can create message and close ai session" do
    school = create_school(name: "ОУ Димитар Миладинов", code: "OU-DM")
    teacher = create_teacher(school: school, email: "ai.teacher@example.com")
    classroom = create_classroom(school: school, teacher: teacher, name: "7-A")
    subject = create_subject(school: school, teacher: teacher, name: "Математика")
    student = create_student(school: school, classroom: classroom, email: "ai.student@example.com")
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher, title: "Линеарни равенки")
    step = create_assignment_step(assignment: assignment, position: 1, title: "Чекор 1", prompt: "Поедностави ја равенката")
    submission = create_submission(assignment: assignment, student: student, status: :in_progress, started_at: Time.current, submitted_at: nil)

    headers = auth_headers_for(student, school: school)

    post "/api/v1/ai_sessions", params: {
      assignment_id: assignment.id,
      submission_id: submission.id,
      subject_id: subject.id,
      title: "Помош по математика",
      session_type: "assignment_help",
      context_data: { topic: "дробки" }
    }, headers: headers
    assert_response :created
    session_payload = JSON.parse(response.body)

    post "/api/v1/ai_sessions/#{session_payload['id']}/messages", params: {
      role: "user",
      message_type: "question",
      content: "Како да почнам?",
      metadata: { assignment_step_id: step.id }
    }, headers: headers
    assert_response :created
    message_payload = JSON.parse(response.body)
    assert_equal 1, message_payload.dig("user_message", "sequence_number")
    assert_equal 2, message_payload.dig("assistant_message", "sequence_number")
    assert_equal "assistant", message_payload.dig("assistant_message", "role")
    assert_equal step.id, message_payload.dig("assistant_message", "metadata", "assignment_step_id")
    assert_match(/Поедностави ја равенката|Чекор 1/, message_payload.dig("assistant_message", "content"))

    get "/api/v1/ai_sessions/#{session_payload['id']}", headers: headers
    assert_response :success
    reloaded = JSON.parse(response.body)
    assert_equal 2, reloaded["messages"].length

    post "/api/v1/ai_sessions/#{session_payload['id']}/close", headers: headers
    assert_response :success
    closed = JSON.parse(response.body)
    assert_equal "completed", closed["status"]
  end
end
