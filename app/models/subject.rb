class Subject < ApplicationRecord
  belongs_to :school

  has_many :teacher_subjects, dependent: :destroy
  has_many :teachers, through: :teacher_subjects, source: :teacher

  has_many :assignments, dependent: :destroy

  validates :name, presence: true
end
