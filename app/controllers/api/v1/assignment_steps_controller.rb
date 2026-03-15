module Api
  module V1
    class AssignmentStepsController < BaseController
      include AssignmentStepSerialization

      before_action :set_assignment

      def create
        require_role!("teacher", "admin")
        return if performed?
        return render_forbidden unless can_manage_assignment?

        step = @assignment.assignment_steps.new(step_params)
        step.content_json = normalized_content_json if step_request_param_key?(:content_json)
        if save_step_with_answer_keys(step)
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
        attributes[:content_json] = normalized_content_json if step_request_param_key?(:content_json)
        step.assign_attributes(attributes)

        if save_step_with_answer_keys(step)
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
        ActionController::Parameters.new(step_request_params.to_unsafe_h.slice(
          "position",
          "title",
          "content",
          "prompt",
          "resource_url",
          "example_answer",
          "step_type",
          "evaluation_mode",
          "required",
          "metadata"
        )).permit(:position, :title, :content, :prompt, :resource_url, :example_answer, :step_type, :evaluation_mode, :required, metadata: {})
      end

      def step_request_params
        wrapped_params = request_body_params[:assignment_step]
        if wrapped_params.is_a?(ActionController::Parameters) && wrapped_params.present?
          ActionController::Parameters.new(
            request_body_params.to_unsafe_h.except("assignment_step").merge(wrapped_params.to_unsafe_h)
          )
        else
          request_body_params
        end
      end

      def normalized_content_json
        value = step_request_params[:content_json]
        return [] if value.blank?
        return value.map { |item| item.respond_to?(:to_unsafe_h) ? item.to_unsafe_h : item } if value.is_a?(Array)

        value.respond_to?(:to_unsafe_h) ? value.to_unsafe_h : value
      end

      def normalized_answer_keys
        Array(step_request_params[:answer_keys]).map.with_index do |answer_key, index|
          raw_answer_key = answer_key.respond_to?(:to_unsafe_h) ? answer_key.to_unsafe_h : answer_key.to_h
          raw_answer_key.symbolize_keys.slice(:value, :tolerance, :case_sensitive, :metadata).merge(
            position: raw_answer_key["position"].presence || raw_answer_key[:position].presence || (index + 1)
          )
        end
      end

      def save_step_with_answer_keys(step)
        AssignmentStep.transaction do
          step.save!
          sync_answer_keys!(step) if step_request_param_key?(:answer_keys)
        end

        true
      rescue ActiveRecord::RecordInvalid
        false
      end

      def sync_answer_keys!(step)
        step.assignment_step_answer_keys.destroy_all

        normalized_answer_keys.each do |answer_key|
          step.assignment_step_answer_keys.create!(
            value: answer_key[:value],
            position: answer_key[:position],
            tolerance: answer_key[:tolerance],
            case_sensitive: ActiveModel::Type::Boolean.new.cast(answer_key[:case_sensitive]) || false,
            metadata: answer_key[:metadata] || {}
          )
        end
      end

      def serialize_step(step)
        serialize_assignment_step(step.reload, include_answer_keys: true)
      end

      def step_request_param_key?(key)
        step_request_params.key?(key) || step_request_params.key?(key.to_s)
      end

      def request_body_params
        @request_body_params ||= ActionController::Parameters.new(request.request_parameters)
      end
    end
  end
end
