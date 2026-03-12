module Api
  module V1
    class SubmissionsController < BaseController
      before_action :set_submission, only: %i[update submit]

      def create
        assignment = Assignment.find_by(id: params[:assignment_id])
        return render_not_found unless assignment

        student = resolve_student_for_create(assignment)
        return render_forbidden unless student

        result = Submissions::Start.new(assignment: assignment, student: student).call
        if result.success?
          log_activity(action: "submission_started", trackable: result.submission, metadata: { submission_id: result.submission.id })
          render json: serialize_submission(result.submission), status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      def update
        return render_forbidden unless can_update_submission?(@submission)

        errors = []
        step_answers = submission_params[:step_answers] || []
        if step_answers.empty? && submission_params[:assignment_step_id].present?
          step_answers = [
            {
              assignment_step_id: submission_params[:assignment_step_id],
              answer_text: submission_params[:answer_text],
              answer_data: submission_params[:answer_data],
              status: submission_params[:status]
            }
          ]
        end

        Submission.transaction do
          step_answers.each do |answer|
            step = @submission.assignment.assignment_steps.find_by(id: answer[:assignment_step_id])
            next unless step

            result = Submissions::SaveStepAnswer.new(
              submission: @submission,
              assignment_step: step,
              answer_text: answer[:answer_text],
              answer_data: answer[:answer_data] || {},
              status: answer[:status].presence || :answered
            ).call
            errors.concat(result.errors) unless result.success?
          end

          @submission.update!(feedback: submission_params[:feedback]) if submission_params.key?(:feedback)
        end

        if errors.any?
          render json: { errors: errors.uniq }, status: :unprocessable_entity
        else
          log_activity(action: "submission_updated", trackable: @submission, metadata: { submission_id: @submission.id })
          render json: serialize_submission(@submission.reload)
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def submit
        return render_forbidden unless can_submit_submission?(@submission)

        result = Submissions::Submit.new(submission: @submission).call
        if result.success?
          log_activity(action: "submission_submitted", trackable: @submission, metadata: { submission_id: @submission.id })
          render json: serialize_submission(@submission.reload)
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def set_submission
        @submission = Submission.includes(:assignment, :student, :submission_step_answers).find_by(id: params[:id])
        render_not_found unless @submission
      end

      def resolve_student_for_create(assignment)
        if current_user.has_role?("student")
          return nil unless assignment.classroom.students.exists?(id: current_user.id)

          current_user
        elsif current_user.has_any_role?("teacher", "admin")
          student = User.find_by(id: params[:student_id])
          return nil unless student
          return nil unless assignment.classroom.students.exists?(id: student.id)

          student
        end
      end

      def can_update_submission?(submission)
        current_user.has_role?("admin") ||
          submission.student_id == current_user.id ||
          submission.assignment.teacher_id == current_user.id
      end

      def can_submit_submission?(submission)
        current_user.has_role?("admin") || submission.student_id == current_user.id
      end

      def submission_params
        params.permit(
          :feedback,
          :assignment_step_id,
          :answer_text,
          :status,
          answer_data: {},
          step_answers: [:assignment_step_id, :answer_text, :status, { answer_data: {} }]
        )
      end

      def serialize_submission(submission)
        {
          id: submission.id,
          assignment_id: submission.assignment_id,
          student_id: submission.student_id,
          status: submission.status,
          started_at: submission.started_at,
          submitted_at: submission.submitted_at,
          reviewed_at: submission.reviewed_at,
          late: submission.late,
          total_score: submission.total_score,
          feedback: submission.feedback,
          step_answers: submission.submission_step_answers.order(:assignment_step_id).map do |step_answer|
            {
              id: step_answer.id,
              assignment_step_id: step_answer.assignment_step_id,
              answer_text: step_answer.answer_text,
              answer_data: step_answer.answer_data,
              status: step_answer.status,
              answered_at: step_answer.answered_at
            }
          end
        }
      end
    end
  end
end
