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
  end
end
