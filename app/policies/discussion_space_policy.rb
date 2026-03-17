class DiscussionSpacePolicy
  include DiscussionPolicySupport

  def initialize(user, space)
    @user = user
    @space = space
  end

  def show?
    return false unless user && space
    return false unless can_access_space_scope?(space)
    return false if blocked_by_visibility?(space)

    space.active? || moderate?
  end

  def create_thread?
    return false unless show?
    return false if space.hidden? || space.archived?
    return true if moderate?

    !space.read_only?
  end

  def reply?
    create_thread?
  end

  def moderate?
    moderator_for_space?(space)
  end

  private

  attr_reader :user, :space
end
