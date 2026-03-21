require "test_helper"

# AI tests are disabled by default to avoid accidental provider usage and cost.
# Run explicitly only when intended:
#   RUN_AI_TESTS=true bin/rails test test/integration/api/v1/ai_sessions_flow_test.rb
return unless ENV["RUN_AI_TESTS"] == "true"

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

  test "student is limited to three ai questions per step" do
    school = create_school(name: "ОУ Браќа Миладиновци", code: "OU-BM")
    teacher = create_teacher(school: school, email: "ai.limit.teacher@example.com")
    classroom = create_classroom(school: school, teacher: teacher, name: "8-A")
    subject = create_subject(school: school, teacher: teacher, name: "Физика")
    student = create_student(school: school, classroom: classroom, email: "ai.limit.student@example.com")
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher, title: "Движење")
    step = create_assignment_step(assignment: assignment, position: 1, title: "Чекор 1", prompt: "Опиши го движењето")
    submission = create_submission(assignment: assignment, student: student, status: :in_progress, started_at: Time.current, submitted_at: nil)

    headers = auth_headers_for(student, school: school)

    post "/api/v1/ai_sessions", params: {
      assignment_id: assignment.id,
      submission_id: submission.id,
      subject_id: subject.id,
      title: "Помош по физика",
      session_type: "assignment_help"
    }, headers: headers
    assert_response :created
    session_id = JSON.parse(response.body)["id"]

    3.times do |index|
      post "/api/v1/ai_sessions/#{session_id}/messages", params: {
        role: "user",
        message_type: "question",
        content: "Прашање #{index + 1}",
        metadata: { assignment_step_id: step.id }
      }, headers: headers

      assert_response :created
    end

    post "/api/v1/ai_sessions/#{session_id}/messages", params: {
      role: "user",
      message_type: "question",
      content: "Прашање 4",
      metadata: { assignment_step_id: step.id }
    }, headers: headers

    assert_response :too_many_requests
    payload = JSON.parse(response.body)
    assert_equal "step_question_limit_reached", payload["code"]
    assert_equal step.id, payload["assignment_step_id"]
    assert_equal 3, payload["limit"]

    get "/api/v1/ai_sessions/#{session_id}", headers: headers
    assert_response :success
    reloaded = JSON.parse(response.body)
    assert_equal 6, reloaded["messages"].length
  end

  test "student can send ai message with nested ai_message params" do
    school = create_school(name: "ОУ Кирил Пејчиновиќ", code: "OU-KP")
    teacher = create_teacher(school: school, email: "ai.nested.teacher@example.com")
    classroom = create_classroom(school: school, teacher: teacher, name: "6-A")
    subject = create_subject(school: school, teacher: teacher, name: "Историја")
    student = create_student(school: school, classroom: classroom, email: "ai.nested.student@example.com")
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher, title: "Среден век")
    step = create_assignment_step(assignment: assignment, position: 1, title: "Чекор 1", prompt: "Опиши го настанот")
    submission = create_submission(assignment: assignment, student: student, status: :in_progress, started_at: Time.current, submitted_at: nil)

    headers = auth_headers_for(student, school: school)

    post "/api/v1/ai_sessions", params: {
      assignment_id: assignment.id,
      submission_id: submission.id,
      subject_id: subject.id,
      title: "Помош по историја",
      session_type: "assignment_help"
    }, headers: headers
    assert_response :created
    session_id = JSON.parse(response.body)["id"]

    post "/api/v1/ai_sessions/#{session_id}/messages", params: {
      ai_message: {
        role: "user",
        message_type: "question",
        content: "Како да почнам?",
        metadata: { assignment_step_id: step.id }
      }
    }, headers: headers

    assert_response :created
    payload = JSON.parse(response.body)
    assert_equal "user", payload.dig("user_message", "role")
    assert_equal "assistant", payload.dig("assistant_message", "role")
    assert_equal step.id, payload.dig("assistant_message", "metadata", "assignment_step_id")
  end

  test "student question is rejected when longer than 100 characters" do
    school = create_school(name: "ОУ Кочо Рацин", code: "OU-KR")
    teacher = create_teacher(school: school, email: "ai.length.teacher@example.com")
    classroom = create_classroom(school: school, teacher: teacher, name: "6-B")
    subject = create_subject(school: school, teacher: teacher, name: "Македонски")
    student = create_student(school: school, classroom: classroom, email: "ai.length.student@example.com")
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher, title: "Писмена задача")
    step = create_assignment_step(assignment: assignment, position: 1, title: "Чекор 1", prompt: "Напиши кратко објаснување")
    submission = create_submission(assignment: assignment, student: student, status: :in_progress, started_at: Time.current, submitted_at: nil)

    headers = auth_headers_for(student, school: school)

    post "/api/v1/ai_sessions", params: {
      assignment_id: assignment.id,
      submission_id: submission.id,
      subject_id: subject.id,
      title: "Помош по македонски",
      session_type: "assignment_help"
    }, headers: headers
    assert_response :created
    session_id = JSON.parse(response.body)["id"]

    post "/api/v1/ai_sessions/#{session_id}/messages", params: {
      role: "user",
      message_type: "question",
      content: ("а" * 101),
      metadata: { assignment_step_id: step.id }
    }, headers: headers

    assert_response :unprocessable_entity
    payload = JSON.parse(response.body)
    assert_equal "ai_question_too_long", payload["code"]
    assert_equal 100, payload["max_length"]
  end

  test "student asking for ready-made sources gets a safe boundary response" do
    school = create_school(name: "ОУ Гоце Делчев", code: "OU-GD")
    teacher = create_teacher(school: school, email: "ai.boundary.teacher@example.com")
    classroom = create_classroom(school: school, teacher: teacher, name: "7-B")
    subject = create_subject(school: school, teacher: teacher, name: "Историја")
    student = create_student(school: school, classroom: classroom, email: "ai.boundary.student@example.com")
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher, title: "Презентација")
    step = create_assignment_step(assignment: assignment, position: 1, title: "Чекор 1", prompt: "Истражување")
    submission = create_submission(assignment: assignment, student: student, status: :in_progress, started_at: Time.current, submitted_at: nil)

    headers = auth_headers_for(student, school: school)

    post "/api/v1/ai_sessions", params: {
      assignment_id: assignment.id,
      submission_id: submission.id,
      subject_id: subject.id,
      title: "Помош по историја",
      session_type: "assignment_help"
    }, headers: headers
    assert_response :created
    session_id = JSON.parse(response.body)["id"]

    post "/api/v1/ai_sessions/#{session_id}/messages", params: {
      role: "user",
      message_type: "question",
      content: "Може ли да ми спремиш извори и линкови за презентација?",
      metadata: { assignment_step_id: step.id }
    }, headers: headers

    assert_response :created
    payload = JSON.parse(response.body)
    assistant_message = payload["assistant_message"]

    assert_equal "policy", assistant_message.dig("metadata", "provider")
    assert_equal "resource_boundary", assistant_message.dig("metadata", "policy")
    assert_operator assistant_message["content"].split(/\s+/).length, :<=, 50
    assert_includes assistant_message["content"], "Не можам"
  end
end
