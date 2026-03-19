module Api
  module V1
    module Student
      class LearningGamesController < BaseController
        before_action :require_student!
        before_action :require_school_context!

        def index
          render json: QuizGames::LearningGamesAvailabilityService.new(school: school).call
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
      end
    end
  end
end
