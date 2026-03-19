module QuizGames
  class DailyQuizAnswerService
    Result = Struct.new(:success?, :payload, :errors, :http_status, :answer, keyword_init: true)

    def initialize(student:, school:, params:)
      @student = student
      @school = school
      @params = params
    end

    def call
      window = FeatureWindow.new(school: school)
      question = question_for(window.current_date)
      return failure(status: :not_found, errors: ["No active daily quiz is configured for today"]) unless question

      validate_requested_question!(question)
      existing_answer = DailyQuizAnswer.includes(:daily_quiz_question).find_by(
        school: school,
        student: student,
        quiz_date: window.current_date
      )
      return existing_answer_result(existing_answer) if existing_answer

      validate_answer_payload!(question)

      answer = nil
      created = false

      DailyQuizAnswer.transaction do
        answer = DailyQuizAnswer.lock.find_by(school: school, student: student, quiz_date: window.current_date)

        if answer
          ensure_reward_for(answer)
        else
          answer = DailyQuizAnswer.create!(build_answer_attributes(question, window.current_date))
          ensure_reward_for(answer)
          created = true
        end
      end

      refresh_progress_profile

      Result.new(
        success?: true,
        payload: serialize_answer(answer, question),
        errors: [],
        http_status: created ? :created : :ok,
        answer: answer
      )
    rescue ActiveRecord::RecordInvalid => e
      failure(status: :unprocessable_entity, errors: e.record.errors.full_messages, answer: e.record)
    rescue ActiveRecord::RecordNotUnique
      retry_existing_answer(window.current_date)
    rescue ArgumentError => e
      failure(status: :unprocessable_entity, errors: [e.message])
    end

    private

    attr_reader :student, :school, :params

    def question_for(quiz_date)
      school_question = DailyQuizQuestion.active.find_by(school: school, quiz_date: quiz_date)
      school_question || DailyQuizQuestion.active.find_by(school_id: nil, quiz_date: quiz_date)
    end

    def validate_requested_question!(question)
      requested_question_id = params[:daily_quiz_question_id].presence
      raise ArgumentError, "daily_quiz_question_id is required" if requested_question_id.blank?
      raise ArgumentError, "Question does not match today's daily quiz" if requested_question_id.to_i != question.id
    end

    def validate_answer_payload!(question)
      if question.single_choice?
        raise ArgumentError, "selected_answer is required" if params[:selected_answer].blank?

        options = Array(question.answer_options).map(&:to_s)
        return if options.include?(params[:selected_answer].to_s)

        raise ArgumentError, "selected_answer is not a valid option"
      end

      raise ArgumentError, "answer_text is required" if params[:answer_text].blank?
    end

    def build_answer_attributes(question, quiz_date)
      {
        school: school,
        student: student,
        daily_quiz_question: question,
        quiz_date: quiz_date,
        selected_answer: question.single_choice? ? params[:selected_answer].to_s : nil,
        answer_text: question.single_choice? ? nil : params[:answer_text].to_s,
        is_correct: correct_answer?(question),
        answered_at: Time.current
      }
    end

    def correct_answer?(question)
      submitted_value = question.single_choice? ? params[:selected_answer] : params[:answer_text]
      normalize_value(submitted_value) == normalize_value(question.correct_answer)
    end

    def normalize_value(value)
      value.to_s.strip.unicode_normalize(:nfkc).downcase
    end

    def ensure_reward_for(answer)
      return 0 unless answer.is_correct?

      DailyQuizRewardService.new(answer: answer).call
    end

    def serialize_answer(answer, question)
      {
        correct: answer.is_correct,
        xp_awarded: answer.xp_awarded,
        already_answered: true,
        explanation: question.explanation,
        answered_at: answer.answered_at
      }
    end

    def retry_existing_answer(quiz_date)
      answer = DailyQuizAnswer.includes(:daily_quiz_question).find_by(
        school: school,
        student: student,
        quiz_date: quiz_date
      )
      return failure(status: :unprocessable_entity, errors: ["Could not save answer"]) unless answer

      existing_answer_result(answer)
    end

    def existing_answer_result(answer)
      ensure_reward_for(answer)
      refresh_progress_profile

      Result.new(
        success?: true,
        payload: serialize_answer(answer, answer.daily_quiz_question),
        errors: [],
        http_status: :ok,
        answer: answer
      )
    end

    def refresh_progress_profile
      Gamification::RefreshStudentProgress.new(student: student, school: school).call
    rescue StandardError
      nil
    end

    def failure(status:, errors:, answer: nil)
      Result.new(success?: false, payload: nil, errors: errors, http_status: status, answer: answer)
    end
  end
end
