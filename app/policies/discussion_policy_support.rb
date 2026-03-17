module DiscussionPolicySupport
  private

  def school_member?(school)
    return false unless user && school

    user.schools.exists?(id: school.id)
  end

  def moderator_for_space?(space)
    return false unless school_member?(space.school)
    return true if user.has_role?("admin")
    return false unless user.has_role?("teacher")

    case space.space_type
    when "assignment"
      assignment = space.assignment
      return false unless assignment

      assignment.teacher_id == user.id ||
        assignment.classroom.teachers.exists?(id: user.id) ||
        assignment.subject.teachers.exists?(id: user.id)
    when "classroom"
      space.classroom&.teachers&.exists?(id: user.id)
    when "subject"
      space.subject&.teachers&.exists?(id: user.id)
    when "school"
      true
    else
      false
    end
  end

  def visible_assignment_to_student?(assignment)
    return false unless assignment

    assignment.classroom.students.exists?(id: user.id) && !assignment.draft? && !assignment.archived?
  end

  def visible_subject_to_student?(subject)
    return false unless subject

    Assignment.joins(classroom: :classroom_users)
      .where(subject_id: subject.id, classroom_users: { user_id: user.id })
      .where.not(status: Assignment.statuses[:draft])
      .exists?
  end

  def can_access_space_scope?(space)
    return false unless school_member?(space.school)

    case space.space_type
    when "assignment"
      return moderator_for_space?(space) if user.has_any_role?("teacher", "admin")

      user.has_role?("student") && visible_assignment_to_student?(space.assignment)
    when "classroom"
      return moderator_for_space?(space) if user.has_any_role?("teacher", "admin")

      user.has_role?("student") && space.classroom&.students&.exists?(id: user.id)
    when "subject"
      return moderator_for_space?(space) if user.has_any_role?("teacher", "admin")

      user.has_role?("student") && visible_subject_to_student?(space.subject)
    when "school"
      return user.has_any_role?("teacher", "admin") if space.teachers_only?

      true
    else
      false
    end
  end

  def blocked_by_visibility?(space)
    return false unless user
    return false if moderator_for_space?(space)

    space.teachers_only? && user.has_role?("student")
  end
end
