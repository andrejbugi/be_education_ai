class Submission < ApplicationRecord
  belongs_to :assignment
  belongs_to :student, class_name: "User"

  has_many :submission_step_answers, dependent: :destroy
  has_many :grades, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :ai_sessions, dependent: :nullify

  enum :status, {
    not_started: 0,
    in_progress: 1,
    submitted: 2,
    reviewed: 3,
    returned: 4,
    late: 5
  }

  validates :student_id, uniqueness: { scope: :assignment_id }
end
