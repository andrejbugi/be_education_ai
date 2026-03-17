class Announcement < ApplicationRecord
  ALLOWED_FILE_CONTENT_TYPES = AssignmentResource::ALLOWED_FILE_CONTENT_TYPES

  belongs_to :school
  belongs_to :author, class_name: "User"
  belongs_to :classroom, optional: true
  belongs_to :subject, optional: true

  has_many :comments, as: :commentable, dependent: :destroy
  has_one_attached :file

  enum :status, {
    draft: 0,
    published: 1,
    archived: 2
  }

  enum :priority, {
    normal: 0,
    important: 1,
    urgent: 2
  }

  AUDIENCE_TYPES = %w[school classroom subject teachers students].freeze

  scope :published_visible, -> {
    published
      .where("starts_at IS NULL OR starts_at <= ?", Time.current)
      .where("ends_at IS NULL OR ends_at >= ?", Time.current)
  }

  validates :title, :body, :audience_type, presence: true
  validates :audience_type, inclusion: { in: AUDIENCE_TYPES }
  validate :associated_records_belong_to_same_school
  validate :audience_target_presence
  validate :file_type_is_allowed

  def uploaded_file_attached?
    file.attached?
  end

  def visible_to?(user)
    return false unless user.schools.exists?(id: school_id)
    return true if user.has_role?("admin")

    case audience_type
    when "school"
      true
    when "teachers"
      user.has_any_role?("teacher", "admin")
    when "students"
      user.has_role?("student")
    when "classroom"
      classroom.present? && (classroom.students.exists?(id: user.id) || classroom.teachers.exists?(id: user.id))
    when "subject"
      return false unless subject

      subject.teachers.exists?(id: user.id) ||
        Assignment.joins(classroom: :classroom_users)
                  .where(subject_id: subject_id, classroom_users: { user_id: user.id })
                  .exists?
    else
      false
    end
  end

  private

  def associated_records_belong_to_same_school
    if classroom && classroom.school_id != school_id
      errors.add(:classroom_id, "must belong to the same school")
    end

    if subject && subject.school_id != school_id
      errors.add(:subject_id, "must belong to the same school")
    end

    return unless author

    errors.add(:author_id, "must belong to the same school") unless author.schools.exists?(id: school_id)
  end

  def audience_target_presence
    case audience_type
    when "classroom"
      errors.add(:classroom_id, "must be present for classroom audience") if classroom.blank?
    when "subject"
      errors.add(:subject_id, "must be present for subject audience") if subject.blank?
    end
  end

  def file_type_is_allowed
    return unless file.attached?
    return if ALLOWED_FILE_CONTENT_TYPES.include?(file.blob.content_type)

    errors.add(:file, "must be a supported document, image, audio, or video format")
  end
end
