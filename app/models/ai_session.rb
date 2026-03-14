class AiSession < ApplicationRecord
  belongs_to :school
  belongs_to :user
  belongs_to :assignment, optional: true
  belongs_to :submission, optional: true
  belongs_to :subject, optional: true

  has_many :ai_messages, -> { order(:sequence_number) }, dependent: :destroy

  enum :session_type, {
    assignment_help: 0,
    practice: 1,
    revision: 2,
    freeform: 3
  }

  enum :status, {
    active: 0,
    paused: 1,
    completed: 2,
    archived: 3
  }

  validates :started_at, :last_activity_at, presence: true
end
