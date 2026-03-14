module Api
  module V1
    class HomeroomAssignmentsController < BaseController
      def create
        require_role!("teacher", "admin")
        return if performed?

        classroom = Classroom.find_by(id: params[:classroom_id])
        return render_not_found unless classroom
        return render_forbidden unless can_manage_classroom?(classroom)

        teacher = User.find_by(id: homeroom_assignment_params[:teacher_id])
        return render_not_found unless teacher

        result = HomeroomAssignments::AssignTeacher.new(
          classroom: classroom,
          teacher: teacher,
          school: classroom.school,
          starts_on: homeroom_assignment_params[:starts_on].presence || Date.current,
          actor: current_user
        ).call

        if result.success?
          log_activity(action: "homeroom_assigned", trackable: result.assignment, metadata: { classroom_id: classroom.id, teacher_id: teacher.id })
          render json: serialize_assignment(result.assignment), status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      def update
        require_role!("teacher", "admin")
        return if performed?

        assignment = HomeroomAssignment.find_by(id: params[:id])
        return render_not_found unless assignment
        return render_forbidden unless can_manage_classroom?(assignment.classroom)

        if assignment.update(update_params)
          assignment.classroom.teacher_classrooms.where(user_id: assignment.teacher_id).update_all(homeroom: assignment.active?)
          render json: serialize_assignment(assignment.reload)
        else
          render json: { errors: assignment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def can_manage_classroom?(classroom)
        current_user.has_role?("admin") || classroom.teachers.exists?(id: current_user.id)
      end

      def homeroom_assignment_params
        params.permit(:teacher_id, :starts_on)
      end

      def update_params
        params.permit(:active, :starts_on, :ends_on)
      end

      def serialize_assignment(assignment)
        {
          id: assignment.id,
          school_id: assignment.school_id,
          classroom: {
            id: assignment.classroom_id,
            name: assignment.classroom.name
          },
          teacher: {
            id: assignment.teacher_id,
            full_name: assignment.teacher.full_name
          },
          active: assignment.active,
          starts_on: assignment.starts_on,
          ends_on: assignment.ends_on
        }
      end
    end
  end
end
