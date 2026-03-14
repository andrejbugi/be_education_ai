class HomeroomAssignment < ApplicationRecord
  belongs_to :school
  belongs_to :classroom
  belongs_to :teacher, class_name: "User"

  scope :active, -> { where(active: true) }
  scope :current, -> {
    active.where("starts_on <= ?", Date.current)
          .where("ends_on IS NULL OR ends_on >= ?", Date.current)
  }

  validates :starts_on, presence: true
  validate :teacher_belongs_to_school
  validate :classroom_belongs_to_school

  private

  def teacher_belongs_to_school
    return unless school && teacher

    errors.add(:teacher_id, "must belong to school") unless teacher.schools.exists?(id: school_id)
  end

  def classroom_belongs_to_school
    return unless school && classroom

    errors.add(:classroom_id, "must belong to school") unless classroom.school_id == school_id
  end
end
