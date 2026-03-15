module AiTutor
  class QuestionLimit
    MAX_QUESTIONS_PER_STEP = 3

    def initialize(ai_session:, assignment_step:)
      @ai_session = ai_session
      @assignment_step = assignment_step
    end

    def allowed?
      used_count < MAX_QUESTIONS_PER_STEP
    end

    def used_count
      @used_count ||= scoped_messages.count
    end

    def remaining_count
      [MAX_QUESTIONS_PER_STEP - used_count, 0].max
    end

    private

    attr_reader :ai_session, :assignment_step

    def scoped_messages
      AiMessage.joins(:ai_session)
               .where(ai_sessions: { user_id: ai_session.user_id, assignment_id: assignment_step.assignment_id })
               .where(role: AiMessage.roles[:user], message_type: AiMessage.message_types[:question])
               .where("ai_messages.metadata ->> 'assignment_step_id' = ?", assignment_step.id.to_s)
    end
  end
end
