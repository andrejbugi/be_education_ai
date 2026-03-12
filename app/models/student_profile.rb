class StudentProfile < ApplicationRecord
  belongs_to :user
  belongs_to :school, optional: true

  validates :user_id, uniqueness: true
end
