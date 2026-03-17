class DiscussionPost < ApplicationRecord
  STATUSES = %w[visible hidden reported deleted].freeze

  belongs_to :discussion_thread, counter_cache: :posts_count
  belongs_to :author, class_name: "User"
  belongs_to :parent_post, class_name: "DiscussionPost", optional: true

  has_many :replies, class_name: "DiscussionPost", foreign_key: :parent_post_id, dependent: :nullify

  validates :body, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :body_not_blank_after_strip
  validate :parent_post_in_same_thread
  validate :single_reply_level_only

  scope :visible, -> { where(status: "visible", deleted_at: nil) }
  scope :top_level, -> { where(parent_post_id: nil) }

  def visible?
    status == "visible" && deleted_at.nil?
  end

  def hidden?
    status == "hidden"
  end

  private

  def body_not_blank_after_strip
    errors.add(:body, "can't be blank") if body.to_s.strip.blank?
  end

  def parent_post_in_same_thread
    return if parent_post.blank?
    return if parent_post.discussion_thread_id == discussion_thread_id

    errors.add(:parent_post, "must belong to the same thread")
  end

  def single_reply_level_only
    return if parent_post.blank?
    return if parent_post.parent_post_id.blank?

    errors.add(:parent_post, "can only reference a top-level post")
  end
end
