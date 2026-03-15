module Api
  module V1
    module Teacher
      class ClassroomsController < BaseController
        def index
          require_role!("teacher", "admin")
          return if performed?

          limit, offset = pagination_params
          classrooms = base_scope.order(:name).limit(limit).offset(offset)
          render json: classrooms.map { |classroom| classroom_payload(classroom) }
        end

        def show
          require_role!("teacher", "admin")
          return if performed?

          classroom = base_scope.find_by(id: params[:id])
          return render_not_found unless classroom

          render json: classroom_payload(classroom).merge(
            students: classroom.students.select(:id, :first_name, :last_name, :email),
            assignments: classroom.assignments.order(created_at: :desc).limit(20).as_json(only: %i[id title status due_at subject_id])
          )
        end

        private

        def base_scope
          scope = if current_user.has_role?("admin")
                    Classroom.includes(:school)
                  else
                    current_user.teaching_classrooms.includes(:school)
                  end
          school = current_school
          scope = scope.where(school: school) if school
          scope
        end

        def classroom_payload(classroom)
          {
            id: classroom.id,
            name: classroom.name,
            grade_level: classroom.grade_level,
            academic_year: classroom.academic_year,
            school: {
              id: classroom.school_id,
              name: classroom.school.name
            },
            student_count: classroom.classroom_users.count,
            assignment_count: classroom.assignments.count
          }
        end
      end
    end
  end
end
