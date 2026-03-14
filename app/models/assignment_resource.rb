class AssignmentResource < ApplicationRecord
  RESOURCE_TYPES = %w[pdf file image video link text embed].freeze
  ALLOWED_FILE_CONTENT_TYPES = %w[
    application/pdf
    application/msword
    application/vnd.ms-excel
    application/vnd.ms-powerpoint
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/zip
    application/x-zip-compressed
    text/plain
    image/png
    image/jpeg
    image/gif
    image/webp
    video/mp4
    video/webm
    audio/mpeg
    audio/wav
  ].freeze

  belongs_to :assignment
  has_one_attached :file

  validates :title, :resource_type, presence: true
  validates :resource_type, inclusion: { in: RESOURCE_TYPES }
  validates :position, uniqueness: { scope: :assignment_id }
  validate :file_type_is_allowed

  def uploaded_file_attached?
    file.attached?
  end

  private

  def file_type_is_allowed
    return unless file.attached?
    return if ALLOWED_FILE_CONTENT_TYPES.include?(file.blob.content_type)

    errors.add(:file, "must be a supported document, image, audio, or video format")
  end
end
