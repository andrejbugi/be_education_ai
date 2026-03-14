class AttendanceRecord < ApplicationRecord
  belongs_to :school
  belongs_to :classroom
  belongs_to :subject, optional: true
  belongs_to :student, class_name: "User"
  belongs_to :teacher, class_name: "User"

  enum :status, {
    present: 0,
    absent: 1,
    late: 2,
    excused: 3
  }

  validates :attendance_date, presence: true
  validate :members_belong_to_school_and_classroom

  private

  def members_belong_to_school_and_classroom
    return unless school && classroom && student && teacher

    errors.add(:classroom_id, "must belong to school") unless classroom.school_id == school_id
    errors.add(:student_id, "must be enrolled in classroom") unless classroom.students.exists?(id: student_id)
    errors.add(:teacher_id, "must belong to school") unless teacher.schools.exists?(id: school_id)
    errors.add(:subject_id, "must belong to school") if subject && subject.school_id != school_id
  end
end
