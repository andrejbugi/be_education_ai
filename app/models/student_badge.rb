class StudentBadge < ApplicationRecord
  belongs_to :school
  belongs_to :student, class_name: "User"
  belongs_to :student_progress_profile, counter_cache: :badges_count

  validates :code, :name, :awarded_at, presence: true
  validates :code, uniqueness: { scope: %i[school_id student_id] }
end
