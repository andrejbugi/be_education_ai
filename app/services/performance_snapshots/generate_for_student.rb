module PerformanceSnapshots
  class GenerateForStudent
    Result = Struct.new(:success?, :snapshot, :errors, keyword_init: true)

    PERIOD_RANGES = {
      "weekly" => ->(date) { [date.beginning_of_week, date.end_of_week] },
      "monthly" => ->(date) { [date.beginning_of_month, date.end_of_month] },
      "term" => lambda { |date|
        if date.month <= 6
          [Date.new(date.year, 2, 1), Date.new(date.year, 6, 30)]
        else
          [Date.new(date.year, 9, 1), Date.new(date.year, 12, 31)]
        end
      }
    }.freeze

    def initialize(student:, school:, classroom: nil, period_type: "monthly", date: Date.current, period_start: nil, period_end: nil)
      @student = student
      @school = school
      @classroom = classroom
      @period_type = period_type.to_s
      @date = date
      @period_start = period_start
      @period_end = period_end
    end

    def call
      range_start, range_end = resolve_range
      assignments = assignment_scope(range_start, range_end)
      submissions = Submission.where(assignment_id: assignments.select(:id), student_id: student.id).includes(:grades)
      attendance = attendance_scope(range_start, range_end)
      completed_assignment_ids = submissions.where(status: %i[submitted reviewed late]).pluck(:assignment_id)
      in_progress_assignment_ids = submissions.where(status: :in_progress).pluck(:assignment_id)
      overdue_assignments = assignments.where("due_at < ?", Time.current)

      snapshot = StudentPerformanceSnapshot.find_or_initialize_by(
        school: school,
        student: student,
        classroom: classroom,
        period_type: period_type,
        period_start: range_start
      )

      snapshot.period_end = range_end
      snapshot.average_grade = average_grade_for(submissions)
      snapshot.completed_assignments_count = completed_assignment_ids.size
      snapshot.in_progress_assignments_count = in_progress_assignment_ids.size
      snapshot.overdue_assignments_count = overdue_assignments.where.not(id: completed_assignment_ids).count
      snapshot.missed_assignments_count = overdue_assignments.where.not(id: completed_assignment_ids + in_progress_assignment_ids).count
      snapshot.attendance_rate = attendance_rate_for(attendance)
      snapshot.engagement_score = engagement_score_for(snapshot, attendance.count)
      snapshot.snapshot_data = {
        grades_count: submissions.flat_map(&:grades).size,
        attendance_breakdown: attendance.group(:status).count.transform_keys(&:to_s),
        assignment_ids: assignments.pluck(:id)
      }
      snapshot.generated_at = Time.current
      snapshot.save!

      Result.new(success?: true, snapshot: snapshot, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, snapshot: e.record, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :student, :school, :classroom, :period_type, :date, :period_start, :period_end

    def resolve_range
      return [period_start.to_date, period_end.to_date] if period_type == "custom" && period_start.present? && period_end.present?

      PERIOD_RANGES.fetch(period_type, PERIOD_RANGES["monthly"]).call(date.to_date)
    end

    def assignment_scope(range_start, range_end)
      scope = Assignment.joins(classroom: :classroom_users)
                        .where(classroom_users: { user_id: student.id }, classrooms: { school_id: school.id })
                        .where(created_at: range_start.beginning_of_day..range_end.end_of_day)
      scope = scope.where(classroom_id: classroom.id) if classroom
      scope
    end

    def attendance_scope(range_start, range_end)
      scope = student.attendance_records.where(school_id: school.id, attendance_date: range_start..range_end)
      scope = scope.where(classroom_id: classroom.id) if classroom
      scope
    end

    def average_grade_for(submissions)
      scores = submissions.flat_map { |submission| submission.grades.map(&:score) }
      return nil if scores.empty?

      (scores.sum.to_d / scores.size).round(2)
    end

    def attendance_rate_for(attendance)
      total = attendance.count
      return nil if total.zero?

      attended = attendance.where(status: %i[present late excused]).count
      ((attended.to_d / total) * 100).round(2)
    end

    def engagement_score_for(snapshot, attendance_count)
      score = 0
      score += snapshot.completed_assignments_count * 10
      score += snapshot.in_progress_assignments_count * 4
      score += attendance_count.positive? ? snapshot.attendance_rate.to_d / 10 : 0
      [score.round(2), 100].min
    end
  end
end
