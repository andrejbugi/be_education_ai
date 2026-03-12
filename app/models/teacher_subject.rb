class TeacherSubject < ApplicationRecord
  belongs_to :teacher, class_name: "User"
  belongs_to :subject

  validates :subject_id, uniqueness: { scope: :teacher_id }
end
