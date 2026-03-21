require "test_helper"

# AI tests are disabled by default to avoid accidental provider usage and cost.
# Run explicitly only when intended:
#   RUN_AI_TESTS=true bin/rails test test/services/ai_tutor/build_prompt_test.rb
return unless ENV["RUN_AI_TESTS"] == "true"

class AiTutor::BuildPromptTest < ActiveSupport::TestCase
  include ApiTestFactory

  test "system instructions tell the tutor to respond directly to the student's attempt" do
    school = create_school
    teacher = create_teacher(school: school)
    classroom = create_classroom(school: school, teacher: teacher)
    subject = create_subject(school: school, teacher: teacher)
    student = create_student(school: school, classroom: classroom)
    assignment = create_assignment(classroom: classroom, subject: subject, teacher: teacher, title: "Македонски јазик")
    step = create_assignment_step(
      assignment: assignment,
      prompt: "Напиши кратко но прецизно објаснување.",
      content_json: [{ type: "instruction", text: "Објасни еден поим со свои зборови." }]
    )
    submission = create_submission(assignment: assignment, student: student, status: :in_progress, submitted_at: nil)
    ai_session = AiSession.create!(
      school: school,
      user: student,
      assignment: assignment,
      submission: submission,
      subject: subject,
      title: "Помош",
      session_type: :assignment_help,
      status: :active,
      started_at: Time.current,
      last_activity_at: Time.current,
      context_data: { assignment_step_id: step.id }
    )
    user_message = AiMessage.create!(
      ai_session: ai_session,
      role: :user,
      message_type: :question,
      content: "семејство - луѓе што сме во роднинска врска и многу ги сакаме. дали ова звучи океј?",
      sequence_number: 1,
      metadata: { "assignment_step_id" => step.id }
    )

    prompt = AiTutor::BuildPrompt.new(ai_session: ai_session, user_message: user_message).call

    assert_includes prompt[:system_instructions], "If the student already proposed an answer"
    assert_includes prompt[:system_instructions], "Do not ask the student to choose a word"
    assert_includes prompt[:system_instructions], "evaluate their exact wording first"
  end
end
