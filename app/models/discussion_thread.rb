class DiscussionThread < ApplicationRecord
  STATUSES = %w[active archived hidden].freeze

  belongs_to :discussion_space
  belongs_to :creator, class_name: "User"

  has_many :discussion_posts, -> { order(:created_at, :id) }, dependent: :destroy
  has_many :visible_discussion_posts, -> { visible.order(:created_at, :id) }, class_name: "DiscussionPost"

  validates :title, presence: true
  validates :body, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }
  scope :visible_to_students, -> { where(status: "active") }
  scope :ordered_for_space, -> { order(pinned: :desc, last_post_at: :desc, created_at: :desc) }

  def active?
    status == "active"
  end

  def archived?
    status == "archived"
  end

  def hidden?
    status == "hidden"
  end
end
