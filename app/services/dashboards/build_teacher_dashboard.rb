module Dashboards
  class BuildTeacherDashboard
    def initialize(teacher:, school: nil)
      @teacher = teacher
      @school = school
    end

    def call
      classroom_ids = teacher.teaching_classroom_ids

      pending_submissions = Submission.joins(:assignment)
                                      .where(assignments: { teacher_id: teacher.id })
                                      .where(status: [Submission.statuses[:submitted], Submission.statuses[:late]])
                                      .order(submitted_at: :desc)
                                      .limit(10)

      {
        teacher: {
          id: teacher.id,
          full_name: teacher.full_name
        },
        classroom_count: classroom_ids.size,
        student_count: ClassroomUser.where(classroom_id: classroom_ids).distinct.count(:user_id),
        homerooms: serialize_homerooms,
        active_assignments: Assignment.where(teacher_id: teacher.id, status: [Assignment.statuses[:published], Assignment.statuses[:scheduled]]).count,
        review_queue: pending_submissions.map { |submission| serialize_submission(submission) },
        announcement_feed: serialize_announcements,
        upcoming_calendar_events: serialize_events
      }
    end

    private

    attr_reader :teacher, :school

    def serialize_submission(submission)
      {
        submission_id: submission.id,
        assignment_id: submission.assignment_id,
        assignment_title: submission.assignment.title,
        student_id: submission.student_id,
        student_name: submission.student.full_name,
        submitted_at: submission.submitted_at,
        status: submission.status
      }
    end

    def serialize_events
      return [] unless school

      school.calendar_events
            .where("starts_at >= ?", Time.current)
            .order(:starts_at)
            .limit(5)
            .map do |event|
        {
          id: event.id,
          title: event.title,
          starts_at: event.starts_at,
          event_type: event.event_type
        }
      end
    end

    def serialize_homerooms
      teacher.homeroom_assignments.active.includes(:classroom).map do |assignment|
        {
          homeroom_assignment_id: assignment.id,
          classroom_id: assignment.classroom_id,
          classroom_name: assignment.classroom.name,
          starts_on: assignment.starts_on
        }
      end
    end

    def serialize_announcements
      return [] unless school

      school.announcements.where(author_id: teacher.id).order(created_at: :desc).limit(5).map do |announcement|
        {
          id: announcement.id,
          title: announcement.title,
          status: announcement.status,
          published_at: announcement.published_at
        }
      end
    end
  end
end
