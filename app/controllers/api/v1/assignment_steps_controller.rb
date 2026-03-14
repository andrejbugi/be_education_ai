module Api
  module V1
    class AssignmentStepsController < BaseController
      before_action :set_assignment

      def create
        require_role!("teacher", "admin")
        return if performed?
        return render_forbidden unless can_manage_assignment?

        step = @assignment.assignment_steps.new(step_params)
        step.content_json = normalized_content_json if params.key?(:content_json)
        if step.save
          render json: serialize_step(step), status: :created
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

        attributes = step_params.to_h
        attributes[:content_json] = normalized_content_json if params.key?(:content_json)

        if step.update(attributes)
          render json: serialize_step(step)
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
        params.permit(:position, :title, :content, :prompt, :resource_url, :example_answer, :step_type, :required, metadata: {})
      end

      def normalized_content_json
        value = params[:content_json]
        return [] if value.blank?
        return value.map { |item| item.respond_to?(:to_unsafe_h) ? item.to_unsafe_h : item } if value.is_a?(Array)

        value.respond_to?(:to_unsafe_h) ? value.to_unsafe_h : value
      end

      def serialize_step(step)
        step.as_json(only: %i[id assignment_id position title content prompt resource_url example_answer step_type required metadata content_json])
      end
    end
  end
end
