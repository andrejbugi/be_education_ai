module Api
  module V1
    class StudentPerformanceSnapshotsController < BaseController
      def index
        require_role!("teacher", "admin")
        return if performed?

        student = User.find_by(id: params[:id])
        return render_not_found unless student
        return render_forbidden unless accessible_student?(student)

        snapshots = student.student_performance_snapshots.order(period_start: :desc)
        snapshots = snapshots.where(school_id: current_school.id) if current_school
        limit, offset = pagination_params

        render json: snapshots.limit(limit).offset(offset).map do |snapshot|
          {
            id: snapshot.id,
            period_type: snapshot.period_type,
            period_start: snapshot.period_start,
            period_end: snapshot.period_end,
            average_grade: snapshot.average_grade,
            attendance_rate: snapshot.attendance_rate,
            engagement_score: snapshot.engagement_score,
            generated_at: snapshot.generated_at
          }
        end
      end

      private

      def accessible_student?(student)
        return true if current_user.has_role?("admin")

        (student.student_classroom_ids & current_user.teaching_classroom_ids).any?
      end
    end
  end
end
