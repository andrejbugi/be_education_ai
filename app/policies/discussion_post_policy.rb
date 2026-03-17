class DiscussionPostPolicy
  def initialize(user, post)
    @user = user
    @post = post
  end

  def show?
    return false unless thread_policy.show?

    post.visible? || moderate?
  end

  def hide?
    moderate?
  end

  def unhide?
    moderate?
  end

  def moderate?
    thread_policy.moderate?
  end

  private

  attr_reader :user, :post

  def thread_policy
    @thread_policy ||= DiscussionThreadPolicy.new(user, post.discussion_thread)
  end
end
