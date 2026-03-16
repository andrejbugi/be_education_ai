class MessageRead < ApplicationRecord
  belongs_to :message
  belongs_to :user

  validates :read_at, presence: true
  validates :user_id, uniqueness: { scope: :message_id }
end
