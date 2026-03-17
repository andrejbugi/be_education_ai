class School < ApplicationRecord
  has_many :school_users, dependent: :destroy
  has_many :users, through: :school_users

  has_many :teacher_profiles, dependent: :nullify
  has_many :student_profiles, dependent: :nullify

  has_many :classrooms, dependent: :destroy
  has_many :subjects, dependent: :destroy
  has_many :calendar_events, dependent: :destroy
  has_many :homeroom_assignments, dependent: :destroy
  has_many :announcements, dependent: :destroy
  has_many :attendance_records, dependent: :destroy
  has_many :student_performance_snapshots, dependent: :destroy
  has_many :student_progress_profiles, dependent: :destroy
  has_many :student_badges, dependent: :destroy
  has_many :ai_sessions, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :discussion_spaces, dependent: :destroy

  validates :name, presence: true
end
