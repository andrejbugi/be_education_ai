class ActivityLog < ApplicationRecord
  belongs_to :user
  belongs_to :trackable, polymorphic: true, optional: true

  validates :action, :occurred_at, presence: true

  before_validation :set_default_occurred_at, on: :create

  private

  def set_default_occurred_at
    self.occurred_at ||= Time.current
  end
end
