module Api
  module V1
    module Admin
      class ClassroomSchedulesController < BaseController
        include AdminSerialization
        include ScheduleSerialization

        before_action :require_current_school!
        before_action :set_classroom

        def show
          render json: schedule_payload(@classroom)
        end

        def update
          result = ::Admin::ClassroomSchedules::Replace.new(
            classroom: @classroom,
            school: current_school,
            slots: schedule_slots_params
          ).call

          if result.success?
            render json: schedule_payload(@classroom.reload)
          else
            render json: { errors: result.errors }, status: :unprocessable_entity
          end
        end

        private

        def set_classroom
          @classroom = current_school.classrooms.find_by(id: params[:classroom_id])
          render_not_found unless @classroom
        end

        def schedule_slots_params
          params.permit(slots: %i[day_of_week period_number subject_id teacher_id room_name room_label])
                .fetch(:slots, [])
                .map { |slot| slot.to_h.symbolize_keys }
        end

        def schedule_payload(classroom)
          slots = classroom.weekly_schedule_slots.includes(:subject, :teacher).ordered

          {
            classroom: serialize_admin_classroom(classroom),
            slots: slots.map { |slot| serialize_schedule_slot(slot) },
            available_subjects: current_school.subjects.order(:name).map { |subject| serialize_admin_subject(subject) },
            available_teachers: school_teacher_options
          }
        end
        def school_teacher_options
          current_school.users.joins(:roles)
                       .where(roles: { name: "teacher" })
                       .includes(:teacher_profile)
                       .distinct
                       .order(:first_name, :last_name, :email)
                       .map do |teacher|
            {
              id: teacher.id,
              full_name: teacher.full_name,
              room_name: teacher.teacher_profile&.room_name,
              room_label: teacher.teacher_profile&.room_label,
              subject_ids: teacher.subjects.where(school_id: current_school.id).pluck(:id),
              classroom_ids: teacher.teaching_classrooms.where(school_id: current_school.id).pluck(:id)
            }
          end
        end
      end
    end
  end
end
