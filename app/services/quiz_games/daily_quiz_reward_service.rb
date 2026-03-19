module QuizGames
  class DailyQuizRewardService
    XP_AMOUNT = 1

    def initialize(answer:)
      @answer = answer
    end

    def call
      return 0 unless answer.is_correct?

      reward_event = find_or_create_reward_event
      awarded_xp = reward_event.xp_amount
      answer.update_column(:xp_awarded, awarded_xp) if answer.xp_awarded != awarded_xp
      awarded_xp
    end

    private

    attr_reader :answer

    def find_or_create_reward_event
      StudentRewardEvent.find_or_create_by!(
        school: answer.school,
        student: answer.student,
        source_type: StudentRewardEvent::SOURCE_DAILY_QUIZ,
        source_id: answer.daily_quiz_question_id,
        awarded_on: answer.quiz_date
      ) do |event|
        event.xp_amount = XP_AMOUNT
        event.metadata = {
          daily_quiz_answer_id: answer.id,
          daily_quiz_question_id: answer.daily_quiz_question_id
        }
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end
end
