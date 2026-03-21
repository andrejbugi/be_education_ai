module Admin
  module Classrooms
    class Destroy
      Result = Struct.new(:success?, :errors, :blockers, keyword_init: true)

      def initialize(classroom:)
        @classroom = classroom
      end

      def call
        return Result.new(success?: false, errors: ["Classroom cannot be deleted"], blockers: blockers) if blockers.any?

        classroom.destroy!
        Result.new(success?: true, errors: [], blockers: {})
      end

      private

      attr_reader :classroom

      def blockers
        @blockers ||= {
          teacher_assignments: classroom.teacher_classrooms.count,
          student_enrollments: classroom.classroom_users.count,
          assignments: classroom.assignments.count,
          homeroom_assignments: classroom.homeroom_assignments.count,
          announcements: classroom.announcements.count,
          attendance_records: classroom.attendance_records.count,
          performance_snapshots: classroom.student_performance_snapshots.count,
          discussion_spaces: classroom.discussion_spaces.count
        }.select { |_, count| count.positive? }
      end
    end
  end
end
