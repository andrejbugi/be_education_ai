module AiTutor
  class ResolveAssignmentStep
    def initialize(ai_session:, requested_assignment_step_id: nil)
      @ai_session = ai_session
      @requested_assignment_step_id = requested_assignment_step_id
    end

    def call
      return unless assignment

      steps = assignment.assignment_steps.includes(:assignment_step_answer_keys).order(:position).to_a
      return if steps.empty?

      requested_step = steps.find { |step| step.id == requested_assignment_step_id }
      return requested_step if requested_step

      return steps.first unless submission

      step_answers = submission.submission_step_answers.index_by(&:assignment_step_id)
      steps.find do |step|
        answer = step_answers[step.id]
        answer.nil? || !answer.correct?
      end || steps.first
    end

    private

    attr_reader :ai_session, :requested_assignment_step_id

    def requested_assignment_step_id
      value = @requested_assignment_step_id
      return if value.blank?

      value.to_i
    end

    def assignment
      @assignment ||= ai_session.assignment || submission&.assignment
    end

    def submission
      @submission ||= ai_session.submission || resolve_submission_from_assignment
    end

    def resolve_submission_from_assignment
      return unless ai_session.assignment

      ai_session.assignment.submissions.find_by(student_id: ai_session.user_id)
    end
  end
end
