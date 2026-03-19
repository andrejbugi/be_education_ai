module QuizGames
  class DailyQuizAvailabilityService
    def initialize(student:, school:)
      @student = student
      @school = school
    end

    def call
      window = FeatureWindow.new(school: school)
      answer = DailyQuizAnswer.includes(:daily_quiz_question).find_by(
        school: school,
        student: student,
        quiz_date: window.current_date
      )
      question = answer&.daily_quiz_question || question_for(window.current_date)

      {
        date: window.current_date,
        available_now: true,
        available_from: "00:00",
        available_until: "23:59",
        already_answered: answer.present?,
        question: serialize_question(question),
        answer: serialize_answer(answer, question),
        reward: {
          correct_xp: DailyQuizRewardService::XP_AMOUNT
        }
      }
    end

    private

    attr_reader :student, :school

    def question_for(quiz_date)
      school_question = DailyQuizQuestion.active.find_by(school: school, quiz_date: quiz_date)
      school_question || DailyQuizQuestion.active.find_by(school_id: nil, quiz_date: quiz_date)
    end

    def serialize_question(question)
      return nil unless question

      {
        id: question.id,
        title: question.title,
        body: question.body,
        category: question.category,
        difficulty: question.difficulty,
        answer_type: question.answer_type,
        answer_options: question.answer_options
      }
    end

    def serialize_answer(answer, question)
      return nil unless answer

      {
        selected_answer: answer.selected_answer,
        answer_text: answer.answer_text,
        correct: answer.is_correct,
        xp_awarded: answer.xp_awarded,
        explanation: question&.explanation,
        answered_at: answer.answered_at
      }
    end
  end
end
