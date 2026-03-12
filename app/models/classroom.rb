class Classroom < ApplicationRecord
  belongs_to :school

  has_many :classroom_users, dependent: :destroy
  has_many :students, through: :classroom_users, source: :user

  has_many :teacher_classrooms, dependent: :destroy
  has_many :teachers, through: :teacher_classrooms, source: :user

  has_many :assignments, dependent: :destroy

  validates :name, presence: true
end
