module DiscussionSerialization
  private

  def serialize_discussion_space(space)
    policy = DiscussionSpacePolicy.new(current_user, space)
    assignment = space.assignment
    classroom = space.classroom || assignment&.classroom
    subject = space.subject || assignment&.subject

    {
      id: space.id,
      space_type: space.space_type,
      title: space.title,
      description: space.description,
      status: space.status,
      visibility: space.visibility,
      school: {
        id: space.school_id,
        name: space.school.name
      },
      assignment: assignment && {
        id: assignment.id,
        title: assignment.title
      },
      classroom: classroom && {
        id: classroom.id,
        name: classroom.name
      },
      subject: subject && {
        id: subject.id,
        name: subject.name
      },
      permissions: {
        can_view: policy.show?,
        can_create_thread: policy.create_thread?,
        can_reply: policy.reply?,
        can_moderate: policy.moderate?
      }
    }
  end

  def serialize_discussion_thread(thread, include_space: false)
    policy = DiscussionThreadPolicy.new(current_user, thread)
    payload = {
      id: thread.id,
      discussion_space_id: thread.discussion_space_id,
      title: thread.title,
      body: thread.body,
      status: thread.status,
      pinned: thread.pinned,
      locked: thread.locked,
      posts_count: thread.posts_count,
      last_post_at: thread.last_post_at,
      created_at: thread.created_at,
      updated_at: thread.updated_at,
      creator: {
        id: thread.creator_id,
        full_name: thread.creator.full_name,
        role: primary_role_name(thread.creator)
      },
      permissions: {
        can_view: policy.show?,
        can_reply: policy.create_post?,
        can_moderate: policy.moderate?,
        can_lock: policy.lock?,
        can_unlock: policy.unlock?,
        can_pin: policy.pin?,
        can_unpin: policy.unpin?,
        can_archive: policy.archive?
      }
    }

    payload[:discussion_space] = serialize_discussion_space(thread.discussion_space) if include_space
    payload
  end

  def serialize_discussion_post(post)
    {
      id: post.id,
      discussion_thread_id: post.discussion_thread_id,
      author: {
        id: post.author_id,
        full_name: post.author.full_name,
        role: primary_role_name(post.author)
      },
      parent_post_id: post.parent_post_id,
      body: post.body,
      status: post.status,
      edited_at: post.edited_at,
      deleted_at: post.deleted_at,
      created_at: post.created_at,
      updated_at: post.updated_at,
      replies_count: post.replies.visible.count
    }
  end

  def primary_role_name(user)
    return "admin" if user.has_role?("admin")
    return "teacher" if user.has_role?("teacher")

    "student"
  end
end
