class DiscussionThreadPolicy
  def initialize(user, thread)
    @user = user
    @thread = thread
  end

  def show?
    return false unless space_policy.show?

    thread.active? || moderate?
  end

  def create_post?
    return false unless show?
    return false if thread.archived? || thread.hidden? || thread.locked?

    space_policy.reply?
  end

  def moderate?
    space_policy.moderate?
  end

  def lock?
    moderate?
  end

  def unlock?
    moderate?
  end

  def pin?
    moderate?
  end

  def unpin?
    moderate?
  end

  def archive?
    moderate?
  end

  private

  attr_reader :user, :thread

  def space_policy
    @space_policy ||= DiscussionSpacePolicy.new(user, thread.discussion_space)
  end
end
