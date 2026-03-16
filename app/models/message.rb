class Message < ApplicationRecord
  MESSAGE_TYPES = %w[text file image system].freeze
  STATUSES = %w[sent delivered read edited deleted].freeze

  belongs_to :conversation
  belongs_to :sender, class_name: "User"
  belongs_to :reply_to_message, class_name: "Message", optional: true

  has_many :message_reactions, dependent: :destroy
  has_many :message_attachments, dependent: :destroy
  has_many :message_deliveries, dependent: :destroy
  has_many :message_reads, dependent: :destroy

  validates :message_type, presence: true, inclusion: { in: MESSAGE_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :body_or_attachments_present

  scope :visible, -> { where(deleted_at: nil) }

  def recipient_user_ids
    conversation.conversation_participants.active.where.not(user_id: sender_id).pluck(:user_id)
  end

  def refresh_status!
    next_status =
      if deleted_at.present?
        "deleted"
      elsif delivered_to_all_recipients?(message_reads.select(:user_id))
        "read"
      elsif delivered_to_all_recipients?(message_deliveries.select(:user_id))
        "delivered"
      else
        "sent"
      end

    update!(status: next_status) if status != next_status
  end

  private

  def body_or_attachments_present
    return if body.present? || message_attachments.reject(&:marked_for_destruction?).any?

    errors.add(:body, "can't be blank without attachments")
  end

  def delivered_to_all_recipients?(relation)
    recipient_ids = recipient_user_ids
    return false if recipient_ids.empty?

    (recipient_ids - relation.pluck(:user_id)).empty?
  end
end
