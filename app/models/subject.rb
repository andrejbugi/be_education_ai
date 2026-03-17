class Subject < ApplicationRecord
  belongs_to :school

  has_many :teacher_subjects, dependent: :destroy
  has_many :teachers, through: :teacher_subjects, source: :teacher

  has_many :assignments, dependent: :destroy
  has_many :announcements, dependent: :nullify
  has_many :attendance_records, dependent: :nullify
  has_many :ai_sessions, dependent: :nullify
  has_many :discussion_spaces, dependent: :destroy

  validates :name, presence: true
end
