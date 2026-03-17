require "test_helper"

class ConversationChannelTest < ActionCable::Channel::TestCase
  include ApiTestFactory

  test "subscribes active participants to a conversation stream" do
    school = create_school(code: "CABLE-SUB")
    teacher = create_teacher(school: school, email: "cable.sub.teacher@example.com")
    colleague = create_teacher(school: school, email: "cable.sub.colleague@example.com")
    conversation = Conversation.create!(school: school, conversation_type: "direct", created_by: teacher, active: true)
    conversation.conversation_participants.create!(user: teacher, joined_at: Time.current, active: true)
    conversation.conversation_participants.create!(user: colleague, joined_at: Time.current, active: true)

    stub_connection current_user: teacher

    subscribe(conversation_id: conversation.id)

    assert subscription.confirmed?
    assert_has_stream_for conversation
  end

  test "rejects users who are not active participants" do
    school = create_school(code: "CABLE-REJECT")
    teacher = create_teacher(school: school, email: "cable.reject.teacher@example.com")
    colleague = create_teacher(school: school, email: "cable.reject.colleague@example.com")
    outsider = create_teacher(school: school, email: "cable.reject.outsider@example.com")
    conversation = Conversation.create!(school: school, conversation_type: "direct", created_by: teacher, active: true)
    conversation.conversation_participants.create!(user: teacher, joined_at: Time.current, active: true)
    conversation.conversation_participants.create!(user: colleague, joined_at: Time.current, active: true)

    stub_connection current_user: outsider

    subscribe(conversation_id: conversation.id)

    assert subscription.rejected?
  end
end
