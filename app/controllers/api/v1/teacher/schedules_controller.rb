module Api
  module V1
    module Teacher
      class SchedulesController < BaseController
        include ScheduleSerialization

        def show
          require_role!("teacher", "admin")
          return if performed?

          render json: {
            teacher: {
              id: current_user.id,
              full_name: current_user.full_name
            },
            slots: teacher_schedule_slots.map { |slot| serialize_schedule_slot(slot) }
          }
        end

        private

        def teacher_schedule_slots
          scope = WeeklyScheduleSlot.includes(:subject, :teacher, :classroom)
                                    .where(teacher_id: current_user.id)
                                    .ordered
          school = current_school
          scope = scope.where(school: school) if school
          scope
        end
      end
    end
  end
end
