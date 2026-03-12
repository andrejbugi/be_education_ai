class SubmissionStepAnswer < ApplicationRecord
  belongs_to :submission
  belongs_to :assignment_step

  enum :status, {
    unanswered: 0,
    answered: 1,
    skipped: 2,
    correct: 3,
    incorrect: 4
  }

  validates :assignment_step_id, uniqueness: { scope: :submission_id }
end
