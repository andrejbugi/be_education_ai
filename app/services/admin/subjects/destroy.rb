module Admin
  module Subjects
    class Destroy
      Result = Struct.new(:success?, :errors, :blockers, keyword_init: true)

      def initialize(subject:)
        @subject = subject
      end

      def call
        return Result.new(success?: false, errors: ["Subject cannot be deleted"], blockers: blockers) if blockers.any?

        subject.destroy!
        Result.new(success?: true, errors: [], blockers: {})
      end

      private

      attr_reader :subject

      def blockers
        @blockers ||= {
          teacher_assignments: subject.teacher_subjects.count,
          assignments: subject.assignments.count,
          announcements: subject.announcements.count,
          attendance_records: subject.attendance_records.count,
          weekly_schedule_slots: subject.weekly_schedule_slots.count,
          ai_sessions: subject.ai_sessions.count,
          discussion_spaces: subject.discussion_spaces.count
        }.select { |_, count| count.positive? }
      end
    end
  end
end
