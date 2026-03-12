class AssignmentStep < ApplicationRecord
  belongs_to :assignment

  has_many :submission_step_answers, dependent: :destroy

  validates :position, presence: true, uniqueness: { scope: :assignment_id }
end
