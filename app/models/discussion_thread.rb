class DiscussionThread < ApplicationRecord
  STATUSES = %w[active archived hidden].freeze
  ALLOWED_UPLOAD_CONTENT_TYPES = AssignmentResource::ALLOWED_FILE_CONTENT_TYPES

  belongs_to :discussion_space
  belongs_to :creator, class_name: "User"

  has_many :discussion_posts, -> { order(:created_at, :id) }, dependent: :destroy
  has_many :visible_discussion_posts, -> { visible.order(:created_at, :id) }, class_name: "DiscussionPost"
  has_many_attached :uploads

  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :body_or_uploads_present
  validate :uploads_are_allowed

  scope :active, -> { where(status: "active") }
  scope :visible_to_students, -> { where(status: "active") }
  scope :ordered_for_space, -> { order(pinned: :desc, last_post_at: :desc, created_at: :desc) }

  def active?
    status == "active"
  end

  def archived?
    status == "archived"
  end

  def hidden?
    status == "hidden"
  end

  private

  def body_or_uploads_present
    return if body.to_s.strip.present? || uploads.attached?

    errors.add(:body, "can't be blank without uploads")
  end

  def uploads_are_allowed
    uploads.each do |upload|
      next if ALLOWED_UPLOAD_CONTENT_TYPES.include?(upload.blob.content_type)

      errors.add(:uploads, "must be supported documents, images, audio, or video files")
      break
    end
  end
end
