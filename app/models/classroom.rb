class Classroom < ApplicationRecord
  belongs_to :school

  has_many :classroom_users, dependent: :destroy
  has_many :students, through: :classroom_users, source: :user

  has_many :teacher_classrooms, dependent: :destroy
  has_many :teachers, through: :teacher_classrooms, source: :user

  has_many :weekly_schedule_slots, dependent: :destroy
  has_many :assignments, dependent: :destroy
  has_many :homeroom_assignments, dependent: :destroy
  has_one :active_homeroom_assignment, -> { where(active: true).order(starts_on: :desc) }, class_name: "HomeroomAssignment"
  has_many :announcements, dependent: :nullify
  has_many :attendance_records, dependent: :destroy
  has_many :student_performance_snapshots, dependent: :nullify
  has_many :discussion_spaces, dependent: :destroy

  validates :name, presence: true
end
