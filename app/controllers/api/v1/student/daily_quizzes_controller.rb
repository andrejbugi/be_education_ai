module Api
  module V1
    module Student
      class DailyQuizzesController < BaseController
        before_action :require_student!
        before_action :require_school_context!

        def show
          render json: QuizGames::DailyQuizAvailabilityService.new(
            student: current_user,
            school: school
          ).call
        end

        def answer
          result = QuizGames::DailyQuizAnswerService.new(
            student: current_user,
            school: school,
            params: answer_params.to_h.symbolize_keys
          ).call

          if result.success?
            log_activity(
              action: "daily_quiz_answered",
              trackable: result.answer,
              metadata: {
                daily_quiz_question_id: result.answer.daily_quiz_question_id,
                quiz_date: result.answer.quiz_date,
                correct: result.answer.is_correct,
                xp_awarded: result.answer.xp_awarded
              }
            ) if result.http_status == :created

            render json: result.payload, status: result.http_status
          else
            render json: { errors: result.errors }, status: result.http_status
          end
        end

        private

        def require_student!
          require_role!("student")
        end

        def require_school_context!
          return if school

          render json: { error: "School context is invalid" }, status: :forbidden
        end

        def school
          @school ||= current_school || current_user.schools.first
        end

        def answer_params
          params.permit(:daily_quiz_question_id, :selected_answer, :answer_text)
        end
      end
    end
  end
end
