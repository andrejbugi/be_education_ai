class PasswordReset < ApplicationRecord
  RESET_LIFETIME = 30.minutes

  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, :last_sent_at, presence: true

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token.to_s)
  end

  def expired_now?
    expires_at <= Time.current
  end

  def effective_status
    return "used" if used_at?
    return "expired" if expired_now?

    "pending"
  end

  def confirm_allowed?
    effective_status == "pending"
  end
end
