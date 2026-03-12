module Submissions
  class SaveStepAnswer
    Result = Struct.new(:success?, :step_answer, :errors, keyword_init: true)

    def initialize(submission:, assignment_step:, answer_text: nil, answer_data: {}, status: :answered)
      @submission = submission
      @assignment_step = assignment_step
      @answer_text = answer_text
      @answer_data = answer_data || {}
      @status = status
    end

    def call
      step_answer = SubmissionStepAnswer.find_or_initialize_by(
        submission: submission,
        assignment_step: assignment_step
      )

      step_answer.assign_attributes(
        answer_text: answer_text,
        answer_data: answer_data,
        status: status,
        answered_at: Time.current
      )
      step_answer.save!

      submission.update!(status: :in_progress) if submission.not_started?

      Result.new(success?: true, step_answer: step_answer, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, step_answer: e.record, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :submission, :assignment_step, :answer_text, :answer_data, :status
  end
end
