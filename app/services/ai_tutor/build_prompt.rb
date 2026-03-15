module AiTutor
  class BuildPrompt
    MAX_RECENT_MESSAGES = 6

    def initialize(ai_session:, user_message:)
      @ai_session = ai_session
      @user_message = user_message
    end

    def call
      assignment = ai_session.assignment
      submission = ai_session.submission || resolve_submission(assignment)
      assignment_step = resolve_assignment_step(assignment, submission)
      submission_step_answer = resolve_submission_step_answer(submission, assignment_step)

      {
        system_instructions: system_instructions,
        user_input: build_user_input(assignment, assignment_step, submission_step_answer),
        student_question: user_message.content.to_s.strip,
        assignment: serialize_assignment(assignment),
        assignment_step: serialize_assignment_step(assignment_step),
        submission: serialize_submission(submission),
        submission_step_answer: serialize_submission_step_answer(submission_step_answer),
        recent_messages: recent_messages
      }
    end

    private

    attr_reader :ai_session, :user_message

    def system_instructions
      <<~TEXT.strip
        You are a patient school tutor helping a student step-by-step.
        Never give the final answer immediately.
        Use short guidance, ask one guiding question when useful, and keep the reply educational.
        Reply in Macedonian unless the student clearly writes in another language.
      TEXT
    end

    def build_user_input(assignment, assignment_step, submission_step_answer)
      lines = []
      lines << "Student question: #{user_message.content.to_s.strip}"

      if assignment
        lines << "Assignment title: #{assignment.title}"
        lines << "Assignment description: #{assignment.description}" if assignment.description.present?
      end

      if assignment_step
        lines << "Current step title: #{assignment_step.title}" if assignment_step.title.present?
        lines << "Current step prompt: #{assignment_step.prompt}" if assignment_step.prompt.present?
        lines << "Current step content: #{assignment_step.content}" if assignment_step.content.present?
        lines << "Current step evaluation mode: #{assignment_step.evaluation_mode}"
      end

      if submission_step_answer
        lines << "Student current step status: #{submission_step_answer.status}"
        lines << "Student last answer: #{submission_step_answer.answer_text}" if submission_step_answer.answer_text.present?
      end

      if assignment_step&.assignment_step_answer_keys&.any?
        answer_keys = assignment_step.assignment_step_answer_keys.map(&:value).join(" | ")
        lines << "Teacher reference answers (do not reveal directly): #{answer_keys}"
      end

      if recent_messages.any?
        transcript = recent_messages.map { |message| "#{message[:role]}: #{message[:content]}" }.join("\n")
        lines << "Recent conversation:\n#{transcript}"
      end

      lines.join("\n")
    end

    def resolve_submission(assignment)
      return unless assignment

      assignment.submissions.find_by(student_id: ai_session.user_id)
    end

    def resolve_assignment_step(assignment, submission)
      AiTutor::ResolveAssignmentStep.new(
        ai_session: ai_session,
        requested_assignment_step_id: requested_assignment_step_id
      ).call
    end

    def resolve_submission_step_answer(submission, assignment_step)
      return unless submission && assignment_step

      submission.submission_step_answers.find_by(assignment_step_id: assignment_step.id)
    end

    def requested_assignment_step_id
      raw_step_id = user_message.metadata&.[]("assignment_step_id") ||
                    user_message.metadata&.[](:assignment_step_id) ||
                    ai_session.context_data&.[]("assignment_step_id") ||
                    ai_session.context_data&.[](:assignment_step_id)
      raw_step_id.to_i if raw_step_id.present?
    end

    def recent_messages
      @recent_messages ||= ai_session.ai_messages.order(sequence_number: :desc).limit(MAX_RECENT_MESSAGES).reverse.map do |message|
        {
          role: message.role,
          content: message.content
        }
      end
    end

    def serialize_assignment(assignment)
      return unless assignment

      {
        id: assignment.id,
        title: assignment.title,
        description: assignment.description,
        subject_id: assignment.subject_id
      }
    end

    def serialize_assignment_step(step)
      return unless step

      {
        id: step.id,
        position: step.position,
        title: step.title,
        prompt: step.prompt,
        content: step.content,
        evaluation_mode: step.evaluation_mode
      }
    end

    def serialize_submission(submission)
      return unless submission

      {
        id: submission.id,
        status: submission.status
      }
    end

    def serialize_submission_step_answer(step_answer)
      return unless step_answer

      {
        id: step_answer.id,
        status: step_answer.status,
        answer_text: step_answer.answer_text
      }
    end
  end
end
