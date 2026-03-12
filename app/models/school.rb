class School < ApplicationRecord
  has_many :school_users, dependent: :destroy
  has_many :users, through: :school_users

  has_many :teacher_profiles, dependent: :nullify
  has_many :student_profiles, dependent: :nullify

  has_many :classrooms, dependent: :destroy
  has_many :subjects, dependent: :destroy
  has_many :calendar_events, dependent: :destroy

  validates :name, presence: true
end
