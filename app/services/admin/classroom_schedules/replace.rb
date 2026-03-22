module Admin
  module ClassroomSchedules
    class Replace
      Result = Struct.new(:success?, :slots, :errors, keyword_init: true)

      def initialize(classroom:, school:, slots:)
        @classroom = classroom
        @school = school
        @slots = slots
      end

      def call
        created_slots = []

        WeeklyScheduleSlot.transaction do
          classroom.weekly_schedule_slots.delete_all

          created_slots = Array(slots).map do |slot|
            classroom.weekly_schedule_slots.create!(
              school: school,
              subject_id: slot[:subject_id],
              teacher_id: slot[:teacher_id],
              day_of_week: slot[:day_of_week],
              period_number: slot[:period_number],
              room_name: slot[:room_name],
              room_label: slot[:room_label]
            )
          end
        end

        Result.new(success?: true, slots: created_slots, errors: [])
      rescue ActiveRecord::RecordInvalid => e
        Result.new(success?: false, slots: [], errors: e.record.errors.full_messages)
      end

      private

      attr_reader :classroom, :school, :slots
    end
  end
end
