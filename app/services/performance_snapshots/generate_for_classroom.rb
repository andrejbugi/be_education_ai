module PerformanceSnapshots
  class GenerateForClassroom
    Result = Struct.new(:success?, :overview, :errors, keyword_init: true)

    def initialize(classroom:, school:, period_type: "monthly", date: Date.current)
      @classroom = classroom
      @school = school
      @period_type = period_type
      @date = date
    end

    def call
      snapshots = classroom.students.order(:id).map do |student|
        result = PerformanceSnapshots::GenerateForStudent.new(
          student: student,
          school: school,
          classroom: classroom,
          period_type: period_type,
          date: date
        ).call
        result.snapshot if result.success?
      end.compact

      overview = {
        classroom_id: classroom.id,
        classroom_name: classroom.name,
        period_type: period_type,
        generated_at: Time.current,
        student_count: snapshots.size,
        average_grade: aggregate_average(snapshots, :average_grade),
        average_attendance_rate: aggregate_average(snapshots, :attendance_rate),
        average_engagement_score: aggregate_average(snapshots, :engagement_score),
        students: snapshots.map do |snapshot|
          {
            student_id: snapshot.student_id,
            student_name: snapshot.student.full_name,
            average_grade: snapshot.average_grade,
            attendance_rate: snapshot.attendance_rate,
            engagement_score: snapshot.engagement_score,
            completed_assignments_count: snapshot.completed_assignments_count,
            overdue_assignments_count: snapshot.overdue_assignments_count
          }
        end
      }

      Result.new(success?: true, overview: overview, errors: [])
    end

    private

    attr_reader :classroom, :school, :period_type, :date

    def aggregate_average(snapshots, attribute)
      values = snapshots.filter_map { |snapshot| snapshot.public_send(attribute) }
      return nil if values.empty?

      (values.sum.to_d / values.size).round(2)
    end
  end
end
