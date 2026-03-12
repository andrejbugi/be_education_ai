module Submissions
  class Start
    Result = Struct.new(:success?, :submission, :errors, keyword_init: true)

    def initialize(assignment:, student:)
      @assignment = assignment
      @student = student
    end

    def call
      submission = Submission.find_or_initialize_by(assignment: assignment, student: student)

      if submission.new_record?
        submission.status = :in_progress
        submission.started_at = Time.current
      elsif submission.not_started?
        submission.status = :in_progress
        submission.started_at ||= Time.current
      end

      submission.save!

      Result.new(success?: true, submission: submission, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, submission: e.record, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :assignment, :student
  end
end
