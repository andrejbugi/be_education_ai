module Api
  module V1
    class ClassroomPerformanceOverviewsController < BaseController
      def show
        require_role!("teacher", "admin")
        return if performed?

        classroom = Classroom.find_by(id: params[:id])
        return render_not_found unless classroom
        return render_forbidden unless current_user.has_role?("admin") || classroom.teachers.exists?(id: current_user.id)

        school = current_school || classroom.school
        result = PerformanceSnapshots::GenerateForClassroom.new(
          classroom: classroom,
          school: school,
          period_type: params[:period_type].presence || "monthly"
        ).call

        if result.success?
          render json: result.overview
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end
    end
  end
end
