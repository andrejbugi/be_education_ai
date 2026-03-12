module Api
  module V1
    class AssignmentStepsController < BaseController
      before_action :set_assignment

      def create
        require_role!("teacher", "admin")
        return if performed?
        return render_forbidden unless can_manage_assignment?

        step = @assignment.assignment_steps.new(step_params)
        if step.save
          render json: step.as_json(only: %i[id assignment_id position title content step_type required metadata]), status: :created
        else
          render json: { errors: step.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        require_role!("teacher", "admin")
        return if performed?
        return render_forbidden unless can_manage_assignment?

        step = @assignment.assignment_steps.find_by(id: params[:id])
        return render_not_found unless step

        if step.update(step_params)
          render json: step.as_json(only: %i[id assignment_id position title content step_type required metadata])
        else
          render json: { errors: step.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_assignment
        @assignment = Assignment.find_by(id: params[:assignment_id])
        render_not_found unless @assignment
      end

      def can_manage_assignment?
        current_user.has_role?("admin") || @assignment.teacher_id == current_user.id
      end

      def step_params
        params.permit(:position, :title, :content, :step_type, :required, metadata: {})
      end
    end
  end
end
