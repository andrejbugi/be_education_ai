module Submissions
  class Submit
    Result = Struct.new(:success?, :submission, :errors, keyword_init: true)

    def initialize(submission:)
      @submission = submission
    end

    def call
      return Result.new(success?: false, submission: submission, errors: ["Submission already finalized"]) if submission.submitted? || submission.reviewed?

      late = submission.assignment.due_at.present? && Time.current > submission.assignment.due_at
      status = late ? :late : :submitted

      submission.update!(status: status, submitted_at: Time.current, late: late)
      notify_teacher

      Result.new(success?: true, submission: submission, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, submission: e.record, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :submission

    def notify_teacher
      Notifications::Dispatch.new(
        user: submission.assignment.teacher,
        actor: submission.student,
        notification_type: "submission_submitted",
        title: "Нова предадена задача",
        body: submission.assignment.title,
        payload: { submission_id: submission.id, assignment_id: submission.assignment_id }
      ).call
    end
  end
end
