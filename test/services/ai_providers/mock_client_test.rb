require "test_helper"

# AI tests are disabled by default to avoid accidental provider usage and cost.
# Run explicitly only when intended:
#   RUN_AI_TESTS=true bin/rails test test/services/ai_providers/mock_client_test.rb
return unless ENV["RUN_AI_TESTS"] == "true"

class AiProviders::MockClientTest < ActiveSupport::TestCase
  test "gives direct feedback when the student asks if a draft answer sounds okay" do
    client = AiProviders::MockClient.new

    response = client.generate_tutor_response(
      prompt: {
        student_question: "семејство - луѓе што сме во роднинска врска и многу ги сакаме. дали ова звучи океј?",
        assignment_step: {
          id: 1,
          prompt: "Напиши кратко но прецизно објаснување.",
          content: "Објасни еден поим со свои зборови."
        }
      }
    )

    assert_equal "draft_feedback", response.metadata["strategy"]
    assert_includes response.content, "Да, ова звучи"
    refute_includes response.content, "Сакаш да ти помогнам"
  end
end
