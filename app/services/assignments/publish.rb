module Assignments
  class Publish
    Result = Struct.new(:success?, :assignment, :errors, keyword_init: true)

    def initialize(assignment:, actor:)
      @assignment = assignment
      @actor = actor
    end

    def call
      return Result.new(success?: false, assignment: assignment, errors: ["Assignment is already published"]) if assignment.published?

      assignment.update!(status: :published, published_at: Time.current)
      notify_students
      Result.new(success?: true, assignment: assignment, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, assignment: e.record, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :assignment, :actor

    def notify_students
      assignment.classroom.students.find_each do |student|
        Notifications::Dispatch.new(
          user: student,
          actor: actor,
          notification_type: "assignment_published",
          title: "Нова задача",
          body: assignment.title,
          payload: { assignment_id: assignment.id }
        ).call
      end
    end
  end
end
