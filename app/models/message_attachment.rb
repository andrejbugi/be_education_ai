class MessageAttachment < ApplicationRecord
  ATTACHMENT_TYPES = %w[file image pdf].freeze

  belongs_to :message
  has_one_attached :file

  validates :attachment_type, presence: true, inclusion: { in: ATTACHMENT_TYPES }
  validate :file_attached

  before_validation :assign_attachment_metadata

  private

  def assign_attachment_metadata
    return unless file.attached?

    self.attachment_type = inferred_attachment_type
    self.file_name = file.blob.filename.to_s
    self.content_type = file.blob.content_type
    self.file_size = file.blob.byte_size
    self.storage_key = file.blob.key
  end

  def inferred_attachment_type
    return "image" if file.blob.content_type.to_s.start_with?("image/")
    return "pdf" if file.blob.content_type == "application/pdf"

    "file"
  end

  def file_attached
    errors.add(:file, "must be attached") unless file.attached?
  end
end
