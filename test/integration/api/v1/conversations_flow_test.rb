require "test_helper"

class Api::V1::ConversationsFlowTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper

  test "teachers can message each other with attachments reactions and delivery tracking" do
    school = create_school(code: "CHAT-TEACHERS")
    teacher = create_teacher(school: school, email: "chat.teacher.one@example.com", first_name: "Ana", last_name: "Teacher")
    colleague = create_teacher(school: school, email: "chat.teacher.two@example.com", first_name: "Boris", last_name: "Teacher")

    teacher_headers = auth_headers_for(teacher, school: school)
    colleague_headers = auth_headers_for(colleague, school: school)

    post "/api/v1/conversations", params: {
      school_id: school.id,
      conversation_type: "direct",
      participant_ids: [colleague.id]
    }, headers: teacher_headers

    assert_response :created
    conversation_payload = JSON.parse(response.body)
    conversation_id = conversation_payload["id"]
    assert_equal 2, conversation_payload["participants"].length
    assert_equal 0, conversation_payload["unread_count"]

    post "/api/v1/conversations", params: {
      school_id: school.id,
      conversation_type: "direct",
      participant_ids: [colleague.id]
    }, headers: teacher_headers

    assert_response :success
    assert_equal conversation_id, JSON.parse(response.body)["id"]

    stream = ChatRealtime::ConversationStream.name_for(conversation_id)

    assert_broadcasts(stream, 1) do
      post "/api/v1/conversations/#{conversation_id}/messages", params: {
        body: "Please review the attached lesson plan.",
        files: [uploaded_test_file(filename: "lesson-plan.pdf", content_type: "application/pdf", content: "Lesson plan")]
      }, headers: teacher_headers
    end

    assert_response :created
    message_payload = JSON.parse(response.body)
    message_id = message_payload["id"]
    broadcast_payload = JSON.parse(broadcasts(stream).last)
    assert_equal "message.created", broadcast_payload["type"]
    assert_equal conversation_id, broadcast_payload["conversation_id"]
    assert_equal "Please review the attached lesson plan.", broadcast_payload.dig("message", "body")
    assert_equal teacher.id, broadcast_payload.dig("message", "sender_id")
    assert_equal "sent", message_payload["status"]
    assert_equal [teacher.id], message_payload["delivered_user_ids"]
    assert_equal [teacher.id], message_payload["read_user_ids"]
    assert_equal 1, message_payload["attachments"].length
    assert_equal "lesson-plan.pdf", message_payload.dig("attachments", 0, "file_name")
    assert_equal "pdf", message_payload.dig("attachments", 0, "attachment_type")

    get "/api/v1/conversations", headers: colleague_headers
    assert_response :success
    colleague_conversations = JSON.parse(response.body)
    assert_equal 1, colleague_conversations.length
    assert_equal 1, colleague_conversations.first["unread_count"]
    assert_equal "Please review the attached lesson plan.", colleague_conversations.first.dig("last_message", "body")

    post "/api/v1/messages/#{message_id}/deliver", headers: colleague_headers
    assert_response :success
    delivered_payload = JSON.parse(response.body)
    assert_equal "delivered", delivered_payload["status"]
    assert_equal [teacher.id, colleague.id].sort, delivered_payload["delivered_user_ids"].sort

    post "/api/v1/messages/#{message_id}/read", headers: colleague_headers
    assert_response :success
    read_payload = JSON.parse(response.body)
    assert_equal "read", read_payload["status"]
    assert_equal [teacher.id, colleague.id].sort, read_payload["read_user_ids"].sort

    post "/api/v1/messages/#{message_id}/reactions", params: { reaction: "like" }, headers: colleague_headers
    assert_response :created
    reaction_payload = JSON.parse(response.body)
    assert_equal 1, reaction_payload["reactions"].length
    assert_equal "like", reaction_payload.dig("reactions", 0, "reaction")

    post "/api/v1/presence/update", params: { presence: { status: "online" } }, headers: colleague_headers
    assert_response :success
    presence_payload = JSON.parse(response.body)
    assert_equal "online", presence_payload["status"]

    get "/api/v1/conversations/#{conversation_id}/messages", headers: teacher_headers
    assert_response :success
    messages_payload = JSON.parse(response.body)
    assert_equal 1, messages_payload.length
    assert_equal "read", messages_payload.first["status"]
    assert_equal "like", messages_payload.first.dig("reactions", 0, "reaction")

    get "/api/v1/conversations", headers: teacher_headers
    assert_response :success
    refreshed_conversation = JSON.parse(response.body).first
    colleague_state = refreshed_conversation["participants"].find { |participant| participant["id"] == colleague.id }
    assert_equal "online", colleague_state["presence_status"]
    assert_equal 0, refreshed_conversation["unread_count"]
  end

  test "teacher student conversations require a shared classroom and student to student chat stays blocked" do
    school = create_school(code: "CHAT-RULES")
    teacher = create_teacher(school: school, email: "chat.teacher.rules@example.com")
    classroom = create_classroom(school: school, teacher: teacher, name: "8-A")
    other_classroom = create_classroom(school: school, name: "8-B")
    student = create_student(school: school, classroom: classroom, email: "chat.student.allowed@example.com")
    outsider_student = create_student(school: school, classroom: other_classroom, email: "chat.student.blocked@example.com")

    teacher_headers = auth_headers_for(teacher, school: school)
    student_headers = auth_headers_for(student, school: school)

    post "/api/v1/conversations", params: {
      school_id: school.id,
      conversation_type: "direct",
      participant_ids: [student.id]
    }, headers: teacher_headers

    assert_response :created

    post "/api/v1/conversations", params: {
      school_id: school.id,
      conversation_type: "direct",
      participant_ids: [outsider_student.id]
    }, headers: teacher_headers

    assert_response :unprocessable_entity
    outsider_payload = JSON.parse(response.body)
    assert_includes outsider_payload["errors"], "This conversation is not allowed"

    post "/api/v1/conversations", params: {
      school_id: school.id,
      conversation_type: "direct",
      participant_ids: [outsider_student.id]
    }, headers: student_headers

    assert_response :unprocessable_entity
    student_payload = JSON.parse(response.body)
    assert_includes student_payload["errors"], "This conversation is not allowed"
  end
end
