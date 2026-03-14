module Dashboards
  class BuildStudentDashboard
    def initialize(student:, school: nil)
      @student = student
      @school = school
    end

    def call
      assignments = Assignment.joins(classroom: :classroom_users)
                              .where(classroom_users: { user_id: student.id })
                              .where(status: [Assignment.statuses[:published], Assignment.statuses[:scheduled]])
                              .includes(:submissions)
                              .order(:due_at)
                              .limit(5)
      assignments = assignments.for_school(school.id) if school

      {
        student: {
          id: student.id,
          full_name: student.full_name
        },
        next_task: serialize_assignment(assignments.first),
        homework: assignments.map { |assignment| serialize_assignment(assignment) },
        deadlines: serialize_deadlines,
        announcements: serialize_announcements,
        performance_snapshot: serialize_performance_snapshot,
        ai_resume: serialize_ai_resume,
        notifications_unread: student.notifications.unread.count,
        recent_activity: serialize_activity
      }
    end

    private

    attr_reader :student, :school

    def serialize_assignment(assignment)
      return nil unless assignment

      submission = assignment.submissions.find { |record| record.student_id == student.id }

      {
        assignment_id: assignment.id,
        title: assignment.title,
        due_at: assignment.due_at,
        status: submission&.status || "not_started",
        submission_id: submission&.id
      }
    end

    def serialize_deadlines
      relation = Assignment.joins(:classroom)
                           .where(classrooms: { id: student.student_classroom_ids })
                           .where.not(due_at: nil)
                           .order(due_at: :asc)
                           .limit(5)
      relation = relation.for_school(school.id) if school

      relation.map do |assignment|
        {
          assignment_id: assignment.id,
          title: assignment.title,
          due_at: assignment.due_at
        }
      end
    end

    def serialize_activity
      student.activity_logs.order(occurred_at: :desc).limit(10).map do |log|
        {
          id: log.id,
          action: log.action,
          occurred_at: log.occurred_at,
          trackable_type: log.trackable_type,
          trackable_id: log.trackable_id
        }
      end
    end

    def serialize_announcements
      return [] unless school

      school.announcements.published_visible.order(published_at: :desc).limit(5).select do |announcement|
        announcement.visible_to?(student)
      end.map do |announcement|
        {
          id: announcement.id,
          title: announcement.title,
          priority: announcement.priority,
          published_at: announcement.published_at
        }
      end
    end

    def serialize_performance_snapshot
      return nil unless school

      snapshot = PerformanceSnapshots::GenerateForStudent.new(
        student: student,
        school: school,
        period_type: "monthly"
      ).call.snapshot

      return nil unless snapshot

      {
        average_grade: snapshot.average_grade,
        attendance_rate: snapshot.attendance_rate,
        engagement_score: snapshot.engagement_score,
        completed_assignments_count: snapshot.completed_assignments_count
      }
    end

    def serialize_ai_resume
      session = student.ai_sessions.where(school_id: school&.id).active.order(last_activity_at: :desc).first
      return nil unless session

      {
        session_id: session.id,
        title: session.title,
        session_type: session.session_type,
        last_activity_at: session.last_activity_at
      }
    end
  end
end
