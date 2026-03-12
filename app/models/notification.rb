class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :actor, class_name: "User", optional: true

  validates :notification_type, presence: true

  scope :unread, -> { where(read_at: nil) }

  def mark_as_read!
    update!(read_at: Time.current)
  end
end
