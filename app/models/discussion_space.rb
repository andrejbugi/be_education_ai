class DiscussionSpace < ApplicationRecord
  SPACE_TYPES = %w[assignment classroom subject school].freeze
  STATUSES = %w[active archived hidden].freeze
  VISIBILITIES = %w[teachers_only students_and_teachers read_only].freeze

  belongs_to :school
  belongs_to :assignment, optional: true
  belongs_to :classroom, optional: true
  belongs_to :subject, optional: true
  belongs_to :created_by, class_name: "User"

  has_many :discussion_threads, -> { order(pinned: :desc, last_post_at: :desc, created_at: :desc) }, dependent: :destroy

  validates :space_type, presence: true, inclusion: { in: SPACE_TYPES }
  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :visibility, presence: true, inclusion: { in: VISIBILITIES }
  validate :single_scope_reference_present
  validate :scope_reference_matches_space_type
  validate :scope_belongs_to_same_school

  scope :active, -> { where(status: "active") }
  scope :for_space_type, ->(space_type) { where(space_type: space_type) }

  def active?
    status == "active"
  end

  def archived?
    status == "archived"
  end

  def hidden?
    status == "hidden"
  end

  def teachers_only?
    visibility == "teachers_only"
  end

  def read_only?
    visibility == "read_only"
  end

  def scope_record
    assignment || classroom || subject || school
  end

  private

  def single_scope_reference_present
    scoped_count = [assignment_id, classroom_id, subject_id].count(&:present?)
    scoped_count += 1 if space_type == "school"
    return if scoped_count == 1

    errors.add(:base, "Discussion space must have exactly one scope")
  end

  def scope_reference_matches_space_type
    case space_type
    when "assignment"
      errors.add(:assignment, "must be present for assignment spaces") if assignment_id.blank?
      errors.add(:base, "Only assignment_id is allowed for assignment spaces") if classroom_id.present? || subject_id.present?
    when "classroom"
      errors.add(:classroom, "must be present for classroom spaces") if classroom_id.blank?
      errors.add(:base, "Only classroom_id is allowed for classroom spaces") if assignment_id.present? || subject_id.present?
    when "subject"
      errors.add(:subject, "must be present for subject spaces") if subject_id.blank?
      errors.add(:base, "Only subject_id is allowed for subject spaces") if assignment_id.present? || classroom_id.present?
    when "school"
      errors.add(:base, "School spaces cannot point to assignment, classroom, or subject") if assignment_id.present? || classroom_id.present? || subject_id.present?
    end
  end

  def scope_belongs_to_same_school
    case space_type
    when "assignment"
      errors.add(:assignment, "must belong to the same school") if assignment && assignment.classroom.school_id != school_id
    when "classroom"
      errors.add(:classroom, "must belong to the same school") if classroom && classroom.school_id != school_id
    when "subject"
      errors.add(:subject, "must belong to the same school") if subject && subject.school_id != school_id
    end
  end
end
