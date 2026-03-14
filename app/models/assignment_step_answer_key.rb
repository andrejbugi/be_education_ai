class AssignmentStepAnswerKey < ApplicationRecord
  belongs_to :assignment_step

  validates :value, presence: true
  validates :position, uniqueness: { scope: :assignment_step_id }
end
