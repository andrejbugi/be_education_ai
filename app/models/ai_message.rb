class AiMessage < ApplicationRecord
  belongs_to :ai_session

  enum :role, {
    user: 0,
    assistant: 1,
    system: 2
  }

  enum :message_type, {
    question: 0,
    hint: 1,
    feedback: 2,
    step: 3,
    summary: 4,
    error: 5
  }

  validates :content, :sequence_number, presence: true
  validates :sequence_number, uniqueness: { scope: :ai_session_id }
end
