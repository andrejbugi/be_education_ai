class UserPresenceStatus < ApplicationRecord
  STATUSES = %w[online offline away busy].freeze

  belongs_to :user

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :last_seen_at, presence: true
  validates :user_id, uniqueness: true
end
