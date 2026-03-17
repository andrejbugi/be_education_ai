module Gamification
  class RefreshStudentProgress
    Result = Struct.new(:success?, :profile, :errors, keyword_init: true)

    BadgeDefinition = Struct.new(:code, :name, :description, :condition, keyword_init: true)

    BADGE_DEFINITIONS = [
      BadgeDefinition.new(
        code: "first_completion",
        name: "Прва победа",
        description: "Завршена е првата задача.",
        condition: ->(metrics) { metrics[:completed_assignments_count] >= 1 }
      ),
      BadgeDefinition.new(
        code: "streak_3",
        name: "Во серија",
        description: "Активност најмалку 3 дена по ред.",
        condition: ->(metrics) { metrics[:longest_streak] >= 3 }
      ),
      BadgeDefinition.new(
        code: "high_achiever",
        name: "Одличен резултат",
        description: "Просек 90+ со најмалку 3 оценети задачи.",
        condition: ->(metrics) { metrics[:graded_assignments_count] >= 3 && metrics[:average_grade].to_d >= 90 }
      ),
      BadgeDefinition.new(
        code: "attendance_star",
        name: "Редовен ученик",
        description: "Посетеност 95% со најмалку 5 евиденции.",
        condition: ->(metrics) { metrics[:attendance_records_count] >= 5 && metrics[:attendance_rate].to_d >= 95 }
      ),
      BadgeDefinition.new(
        code: "ai_explorer",
        name: "AI истражувач",
        description: "Започната е AI сесија за учење.",
        condition: ->(metrics) { metrics[:ai_sessions_count] >= 1 }
      )
    ].freeze

    def initialize(student:, school:)
      @student = student
      @school = school
    end

    def call
      profile = StudentProgressProfile.find_or_initialize_by(student: student, school: school)
      metrics = calculate_metrics

      ActiveRecord::Base.transaction do
        profile.assign_attributes(
          total_xp: metrics[:total_xp],
          current_level: metrics[:current_level],
          current_streak: metrics[:current_streak],
          longest_streak: metrics[:longest_streak],
          completed_assignments_count: metrics[:completed_assignments_count],
          graded_assignments_count: metrics[:graded_assignments_count],
          average_grade: metrics[:average_grade],
          attendance_rate: metrics[:attendance_rate],
          last_active_on: metrics[:last_active_on],
          last_synced_at: Time.current,
          metadata: metrics[:metadata]
        )
        profile.save!
        ensure_badges!(profile, metrics)
        profile.update_column(:badges_count, profile.student_badges.count) if profile.badges_count != profile.student_badges.size
      end

      Result.new(success?: true, profile: profile.reload, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, profile: e.record, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :student, :school

    def calculate_metrics
      submissions = school_scoped_submissions
      attendance_records = student.attendance_records.where(school_id: school.id)
      ai_sessions = student.ai_sessions.where(school_id: school.id)

      completed_submissions = submissions.select { |submission| submission.submitted? || submission.reviewed? || submission.late? }
      graded_submissions = submissions.filter_map do |submission|
        grade = submission.grades.max_by(&:graded_at)
        [submission, grade] if grade
      end

      present_count = attendance_records.present.count
      late_count = attendance_records.late.count
      excused_count = attendance_records.excused.count

      average_grade = average_grade_for(graded_submissions.map(&:last))
      attendance_rate = attendance_rate_for(attendance_records)
      grade_bonus_xp = graded_submissions.sum { |(_submission, grade)| grade_bonus_for(grade) }
      attendance_xp = (present_count * 3) + (late_count * 2) + excused_count
      ai_xp = (ai_sessions.count * 5) + (ai_sessions.completed.count * 5)
      total_xp = (completed_submissions.count * 30) + (submissions.in_progress.count * 10) + grade_bonus_xp + attendance_xp + ai_xp

      active_dates = collect_active_dates(submissions: submissions, attendance_records: attendance_records, ai_sessions: ai_sessions)
      current_streak, longest_streak, last_active_on = streaks_for(active_dates)
      current_level = [(total_xp / StudentProgressProfile::LEVEL_XP_STEP) + 1, 1].max

      {
        total_xp: total_xp,
        current_level: current_level,
        current_streak: current_streak,
        longest_streak: longest_streak,
        completed_assignments_count: completed_submissions.count,
        graded_assignments_count: graded_submissions.count,
        average_grade: average_grade,
        attendance_rate: attendance_rate,
        attendance_records_count: attendance_records.count,
        ai_sessions_count: ai_sessions.count,
        last_active_on: last_active_on,
        metadata: {
          xp_breakdown: {
            completed_assignments: completed_submissions.count * 30,
            in_progress_assignments: submissions.in_progress.count * 10,
            grade_bonus: grade_bonus_xp,
            attendance: attendance_xp,
            ai_learning: ai_xp
          },
          attendance_breakdown: {
            present: present_count,
            late: late_count,
            excused: excused_count,
            absent: attendance_records.absent.count
          },
          ai_sessions: {
            total: ai_sessions.count,
            completed: ai_sessions.completed.count,
            active: ai_sessions.active.count
          }
        }
      }
    end

    def school_scoped_submissions
      student.submissions
             .joins(assignment: :classroom)
             .where(classrooms: { school_id: school.id })
             .includes(:grades, assignment: :classroom)
    end

    def average_grade_for(grades)
      return nil if grades.empty?

      (grades.sum(&:score).to_d / grades.size).round(2)
    end

    def attendance_rate_for(attendance_records)
      total = attendance_records.count
      return nil if total.zero?

      attended = attendance_records.where(status: %i[present late excused]).count
      ((attended.to_d / total) * 100).round(2)
    end

    def grade_bonus_for(grade)
      max_score = grade.max_score.to_d
      return 0 if max_score <= 0

      percentage = (grade.score.to_d / max_score) * 100
      case percentage
      when 95..1000 then 20
      when 85...95 then 15
      when 70...85 then 10
      when 60...70 then 5
      else 2
      end
    end

    def collect_active_dates(submissions:, attendance_records:, ai_sessions:)
      dates = []

      submissions.find_each do |submission|
        dates << submission.started_at&.to_date
        dates << submission.submitted_at&.to_date
        dates << submission.created_at&.to_date
      end

      attendance_records.find_each do |record|
        dates << record.attendance_date
      end

      ai_sessions.find_each do |session|
        dates << session.started_at&.to_date
        dates << session.last_activity_at&.to_date
      end

      dates.compact.uniq.sort
    end

    def streaks_for(active_dates)
      return [0, 0, nil] if active_dates.empty?

      longest_streak = 1
      running_streak = 1

      active_dates.each_cons(2) do |previous_date, current_date|
        if current_date == previous_date + 1.day
          running_streak += 1
        else
          longest_streak = [longest_streak, running_streak].max
          running_streak = 1
        end
      end
      longest_streak = [longest_streak, running_streak].max

      last_active_on = active_dates.last
      current_streak = if last_active_on >= Date.current - 1.day
        trailing_streak(active_dates)
      else
        0
      end

      [current_streak, longest_streak, last_active_on]
    end

    def trailing_streak(active_dates)
      streak = 1
      active_dates.reverse_each.each_cons(2) do |current_date, previous_date|
        break unless previous_date == current_date - 1.day

        streak += 1
      end
      streak
    end

    def ensure_badges!(profile, metrics)
      BADGE_DEFINITIONS.each do |definition|
        next unless definition.condition.call(metrics)
        next if profile.student_badges.exists?(code: definition.code)

        profile.student_badges.create!(
          school: school,
          student: student,
          code: definition.code,
          name: definition.name,
          description: definition.description,
          awarded_at: Time.current,
          metadata: {
            total_xp: metrics[:total_xp],
            current_level: metrics[:current_level]
          }
        )
      end
    end
  end
end
