class ConversationParticipant < ApplicationRecord
  belongs_to :conversation
  belongs_to :user
  belongs_to :last_read_message, class_name: "Message", optional: true

  validates :joined_at, presence: true
  validates :user_id, uniqueness: { scope: :conversation_id }

  scope :active, -> { where(active: true) }
end
