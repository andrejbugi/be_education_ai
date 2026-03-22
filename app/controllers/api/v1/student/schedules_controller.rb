module Api
  module V1
    module Student
      class SchedulesController < BaseController
        include ScheduleSerialization

        before_action :require_student!

        def show
          render json: {
            student: {
              id: current_user.id,
              full_name: current_user.full_name
            },
            slots: student_schedule_slots.map { |slot| serialize_schedule_slot(slot) }
          }
        end

        private

        def require_student!
          require_role!("student")
        end

        def student_schedule_slots
          classroom_ids = current_user.student_classrooms
                                      .yield_self { |scope| current_school ? scope.where(school: current_school) : scope }
                                      .pluck(:id)

          WeeklyScheduleSlot.includes(:subject, :teacher, :classroom)
                            .where(classroom_id: classroom_ids)
                            .yield_self { |scope| current_school ? scope.where(school: current_school) : scope }
                            .ordered
        end
      end
    end
  end
end
