module Announcements
  class DispatchNotifications
    def initialize(announcement:, actor:)
      @announcement = announcement
      @actor = actor
    end

    def call
      recipient_scope.find_each do |user|
        Notifications::Dispatch.new(
          user: user,
          actor: actor,
          notification_type: "announcement_published",
          title: announcement.title,
          body: announcement.body.truncate(140),
          payload: { announcement_id: announcement.id }
        ).call
      end
    end

    private

    attr_reader :announcement, :actor

    def recipient_scope
      users =
        case announcement.audience_type
        when "teachers"
          announcement.school.users.joins(:roles).where(roles: { name: "teacher" })
        when "students"
          announcement.school.users.joins(:roles).where(roles: { name: "student" })
        when "classroom"
          return User.where(id: []) unless announcement.classroom

          User.where(id: announcement.classroom.students.select(:id)).or(User.where(id: announcement.classroom.teachers.select(:id)))
        when "subject"
          return User.where(id: []) unless announcement.subject

          student_ids = Assignment.joins(classroom: :classroom_users)
                                  .where(subject_id: announcement.subject_id)
                                  .select("classroom_users.user_id")
          User.where(id: student_ids).or(User.where(id: announcement.subject.teachers.select(:id)))
        else
          announcement.school.users
        end

      users.where.not(id: actor&.id).distinct
    end
  end
end
