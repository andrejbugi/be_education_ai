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
        params.permit(:score, :max_score, :feedback)
      end
    end
  end
end
