module Api
  module V1
    module Student
      class PerformanceController < BaseController
        def show
          require_role!("student")
          return if performed?

          school = current_school || current_user.schools.first
          result = PerformanceSnapshots::GenerateForStudent.new(
            student: current_user,
            school: school,
            period_type: params[:period_type].presence || "monthly"
          ).call

          if result.success?
            render json: serialize_snapshot(result.snapshot)
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        private

        def serialize_snapshot(snapshot)
          {
            id: snapshot.id,
            period_type: snapshot.period_type,
            period_start: snapshot.period_start,
            period_end: snapshot.period_end,
            average_grade: snapshot.average_grade,
            completed_assignments_count: snapshot.completed_assignments_count,
            in_progress_assignments_count: snapshot.in_progress_assignments_count,
            overdue_assignments_count: snapshot.overdue_assignments_count,
            missed_assignments_count: snapshot.missed_assignments_count,
            attendance_rate: snapshot.attendance_rate,
            engagement_score: snapshot.engagement_score,
            snapshot_data: snapshot.snapshot_data,
            generated_at: snapshot.generated_at
          }
        end
      end
    end
  end
end
