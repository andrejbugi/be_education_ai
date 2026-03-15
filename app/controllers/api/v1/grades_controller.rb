module Api
  module V1
    class GradesController < BaseController
      def create
        require_role!("teacher", "admin")
        return if performed?

        submission = Submission.find_by(id: params[:submission_id])
        return render_not_found unless submission

        return render_forbidden unless can_grade?(submission)

        result = Grades::Create.new(submission: submission, teacher: current_user, params: grade_params.to_h.symbolize_keys).call
        if result.success?
          log_activity(action: "grade_created", trackable: result.grade, metadata: { submission_id: submission.id, grade_id: result.grade.id })
          render json: result.grade.as_json(only: %i[id submission_id teacher_id score max_score feedback graded_at]), status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def can_grade?(submission)
        current_user.has_role?("admin") || submission.assignment.teacher_id == current_user.id
      end

      def grade_params
        ActionController::Parameters.new(grade_request_params.to_unsafe_h.slice(
          "score",
          "max_score",
          "feedback"
        )).permit(:score, :max_score, :feedback)
      end

      def grade_request_params
        wrapped_params = request_body_params[:grade]
        if wrapped_params.is_a?(ActionController::Parameters) && wrapped_params.present?
          ActionController::Parameters.new(
            request_body_params.to_unsafe_h.except("grade").merge(wrapped_params.to_unsafe_h)
          )
        else
          request_body_params
        end
      end

      def request_body_params
        @request_body_params ||= ActionController::Parameters.new(request.request_parameters)
      end
    end
  end
end
