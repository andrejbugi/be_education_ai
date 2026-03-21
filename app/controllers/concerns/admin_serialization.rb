module AdminSerialization
  private

  def serialize_admin_school(school)
    {
      id: school.id,
      name: school.name,
      code: school.code,
      city: school.city,
      active: school.active,
      settings: school.settings,
      classroom_count: school.classrooms.count,
      subject_count: school.subjects.count,
      teacher_count: school.users.joins(:roles).where(roles: { name: "teacher" }).distinct.count,
      student_count: school.users.joins(:roles).where(roles: { name: "student" }).distinct.count
    }
  end

  def serialize_admin_teacher(user, school:, invitation: nil)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      full_name: user.full_name,
      active: user.active,
      roles: user.roles.pluck(:name),
      school_id: school.id,
      invitation_status: invitation_status_for(user, school: school, role_name: "teacher", invitation: invitation),
      invitation_expires_at: invitation&.expires_at,
      invitation_last_sent_at: invitation&.last_sent_at,
      invitation_accepted_at: invitation&.accepted_at,
      teacher_profile: user.teacher_profile&.as_json(only: %i[id school_id title bio]),
      subject_ids: user.subjects.where(school_id: school.id).pluck(:id),
      classroom_ids: user.teaching_classrooms.where(school_id: school.id).pluck(:id)
    }
  end

  def serialize_admin_student(user, school:, invitation: nil)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      full_name: user.full_name,
      active: user.active,
      roles: user.roles.pluck(:name),
      school_id: school.id,
      invitation_status: invitation_status_for(user, school: school, role_name: "student", invitation: invitation),
      invitation_expires_at: invitation&.expires_at,
      invitation_last_sent_at: invitation&.last_sent_at,
      invitation_accepted_at: invitation&.accepted_at,
      student_profile: user.student_profile&.as_json(only: %i[id school_id student_number grade_level guardian_name guardian_phone]),
      classroom_ids: user.student_classrooms.where(school_id: school.id).pluck(:id)
    }
  end

  def serialize_admin_classroom(classroom)
    {
      id: classroom.id,
      school_id: classroom.school_id,
      name: classroom.name,
      grade_level: classroom.grade_level,
      academic_year: classroom.academic_year,
      teacher_ids: classroom.teacher_classrooms.pluck(:user_id),
      student_ids: classroom.classroom_users.pluck(:user_id),
      assignment_count: classroom.assignments.count
    }
  end

  def serialize_admin_subject(subject)
    {
      id: subject.id,
      school_id: subject.school_id,
      name: subject.name,
      code: subject.code,
      topic_count: subject.subject_topics.count,
      teacher_ids: subject.teacher_subjects.pluck(:teacher_id),
      assignment_count: subject.assignments.count
    }
  end

  def serialize_public_invitation(invitation)
    {
      email: invitation.user.email,
      role_name: invitation.role_name,
      status: invitation.effective_status,
      accept_allowed: invitation.accept_allowed?,
      expires_at: invitation.expires_at,
      accepted_at: invitation.accepted_at,
      school: {
        id: invitation.school_id,
        name: invitation.school.name,
        code: invitation.school.code
      },
      user: {
        first_name: invitation.user.first_name,
        last_name: invitation.user.last_name
      }
    }
  end

  def invitation_status_for(user, school:, role_name:, invitation: nil)
    invitation ||= UserInvitation.find_by(user_id: user.id, school_id: school.id, role_name: role_name)
    return invitation.effective_status if invitation
    return "accepted" if user.active?

    nil
  end
end
