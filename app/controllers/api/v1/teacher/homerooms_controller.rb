module Api
  module V1
    module Teacher
      class HomeroomsController < BaseController
        def index
          require_role!("teacher", "admin")
          return if performed?

          scope = HomeroomAssignment.includes(:classroom, :school, :teacher).active.order(starts_on: :desc)
          scope = scope.where(school_id: current_school.id) if current_school
          scope = scope.where(teacher_id: current_user.id) unless current_user.has_role?("admin")
          limit, offset = pagination_params

          render json: scope.limit(limit).offset(offset).map do |assignment|
            {
              id: assignment.id,
              school_name: assignment.school.name,
              classroom_id: assignment.classroom_id,
              classroom_name: assignment.classroom.name,
              starts_on: assignment.starts_on,
              ends_on: assignment.ends_on,
              active: assignment.active
            }
          end
        end
      end
    end
  end
end
