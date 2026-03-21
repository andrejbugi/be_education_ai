class AuthSession < ApplicationRecord
  SESSION_LIFETIME = 7.days

  belongs_to :user
  belongs_to :current_school, class_name: "School", optional: true

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token.to_s)
  end

  def active_now?
    revoked_at.nil? && expires_at.future?
  end

  def revoke!
    update!(revoked_at: Time.current) unless revoked_at?
  end
end
