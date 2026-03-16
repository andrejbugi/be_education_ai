class Conversation < ApplicationRecord
  belongs_to :school
  belongs_to :created_by, class_name: "User"
  belongs_to :last_message, class_name: "Message", optional: true

  has_many :conversation_participants, dependent: :destroy
  has_many :participants, through: :conversation_participants, source: :user
  has_many :active_conversation_participants, -> { where(active: true).order(:created_at) }, class_name: "ConversationParticipant"
  has_many :active_participants, through: :active_conversation_participants, source: :user
  has_many :messages, -> { order(:created_at, :id) }, dependent: :destroy

  validates :conversation_type, presence: true, inclusion: { in: %w[direct group] }

  scope :active, -> { where(active: true) }
  scope :direct, -> { where(conversation_type: "direct") }
  scope :group_conversations, -> { where(conversation_type: "group") }
  scope :recent_first, -> { order(Arel.sql("COALESCE(last_message_at, conversations.created_at) DESC")) }

  def participant_for(user)
    conversation_participants.find_by(user_id: user.id)
  end

  def direct?
    conversation_type == "direct"
  end

  def group?
    conversation_type == "group"
  end
end
