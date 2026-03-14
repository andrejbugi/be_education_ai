class StudentPerformanceSnapshot < ApplicationRecord
  belongs_to :school
  belongs_to :student, class_name: "User"
  belongs_to :classroom, optional: true

  enum :period_type, {
    weekly: 0,
    monthly: 1,
    term: 2,
    custom: 3
  }

  validates :period_start, :period_end, :generated_at, presence: true
end
