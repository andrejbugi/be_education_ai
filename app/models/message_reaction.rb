class MessageReaction < ApplicationRecord
  REACTIONS = %w[like heart laugh check].freeze

  belongs_to :message
  belongs_to :user

  validates :reaction, presence: true, inclusion: { in: REACTIONS }
  validates :reaction, uniqueness: { scope: %i[message_id user_id] }
end
