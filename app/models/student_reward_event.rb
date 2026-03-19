class StudentRewardEvent < ApplicationRecord
  SOURCE_DAILY_QUIZ = "daily_quiz"

  belongs_to :school
  belongs_to :student, class_name: "User"

  validates :source_type, :source_id, :awarded_on, presence: true
  validates :xp_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :source_id, uniqueness: { scope: %i[school_id student_id source_type awarded_on] }
end
