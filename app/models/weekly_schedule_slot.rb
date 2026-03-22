class WeeklyScheduleSlot < ApplicationRecord
  DAY_NAMES = %w[monday tuesday wednesday thursday friday saturday sunday].freeze

  belongs_to :school
  belongs_to :classroom
  belongs_to :subject
  belongs_to :teacher, class_name: "User"

  enum :day_of_week, DAY_NAMES.each_with_index.to_h, prefix: :day

  validates :day_of_week, presence: true
  validates :period_number, numericality: { only_integer: true, greater_than: 0 }
  validates :period_number, uniqueness: { scope: %i[classroom_id day_of_week] }

  validate :entities_belong_to_same_school
  validate :teacher_has_teacher_role
  validate :teacher_is_assigned_to_subject_and_classroom

  scope :ordered, -> { order(:day_of_week, :period_number, :id) }

  def effective_room_name
    effective_room[:room_name]
  end

  def effective_room_label
    effective_room[:room_label]
  end

  def effective_room_source
    effective_room[:source]
  end

  private

  def effective_room
    @effective_room ||= begin
      room_candidates.find { |candidate| candidate[:room_name].present? || candidate[:room_label].present? } ||
        { source: nil, room_name: nil, room_label: nil }
    end
  end

  def room_candidates
    [
      { source: "slot", room_name: room_name, room_label: room_label },
      { source: "subject_default", room_name: subject&.room_name, room_label: subject&.room_label },
      { source: "teacher_default", room_name: teacher&.teacher_profile&.room_name, room_label: teacher&.teacher_profile&.room_label },
      { source: "classroom_default", room_name: classroom&.room_name, room_label: classroom&.room_label }
    ]
  end

  def entities_belong_to_same_school
    return unless school

    errors.add(:classroom, "must belong to the same school") if classroom && classroom.school_id != school_id
    errors.add(:subject, "must belong to the same school") if subject && subject.school_id != school_id
    errors.add(:teacher, "must belong to the same school") if teacher && !SchoolUser.exists?(school_id: school_id, user_id: teacher_id)
  end

  def teacher_has_teacher_role
    return unless teacher

    errors.add(:teacher, "must have the teacher role") unless teacher.has_role?("teacher")
  end

  def teacher_is_assigned_to_subject_and_classroom
    return unless teacher && subject && classroom

    errors.add(:teacher, "must be assigned to the selected subject") unless TeacherSubject.exists?(teacher_id: teacher_id, subject_id: subject_id)
    errors.add(:teacher, "must be assigned to the selected classroom") unless TeacherClassroom.exists?(user_id: teacher_id, classroom_id: classroom_id)
  end
end
