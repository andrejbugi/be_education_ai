module Grades
  class Create
    Result = Struct.new(:success?, :grade, :errors, keyword_init: true)

    def initialize(submission:, teacher:, params:)
      @submission = submission
      @teacher = teacher
      @params = params
    end

    def call
      grade = nil

      Grade.transaction do
        grade = submission.grades.create!(grade_attributes.merge(teacher: teacher, graded_at: Time.current))
        submission.update!(status: :reviewed, reviewed_at: Time.current, total_score: grade.score)
      end

      notify_student(grade)

      Result.new(success?: true, grade: grade, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, grade: e.record, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :submission, :teacher, :params

    def grade_attributes
      params.slice(:score, :max_score, :feedback)
    end

    def notify_student(grade)
      Notifications::Dispatch.new(
        user: submission.student,
        actor: teacher,
        notification_type: "grade_posted",
        title: "Оценка е објавена",
        body: submission.assignment.title,
        payload: { grade_id: grade.id, submission_id: submission.id }
      ).call
    end
  end
end
