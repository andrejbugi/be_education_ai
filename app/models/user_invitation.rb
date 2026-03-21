class UserInvitation < ApplicationRecord
  ROLE_NAMES = %w[teacher student].freeze

  belongs_to :user
  belongs_to :school
  belongs_to :invited_by, class_name: "User"

  enum :status, { pending: 0, accepted: 1, revoked: 2, expired: 3 }

  validates :role_name, presence: true, inclusion: { in: ROLE_NAMES }
  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validates :last_sent_at, presence: true
  validates :user_id, uniqueness: { scope: %i[school_id role_name] }

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token.to_s)
  end

  def expired_now?
    expires_at <= Time.current
  end

  def effective_status
    return "expired" if pending? && expired_now?

    status
  end

  def accept_allowed?
    effective_status == "pending"
  end

  def mark_expired!
    update!(status: :expired) if pending? && expired_now?
  end
end
