module Api
  module V1
    class StudentAttendanceController < BaseController
      def show
        student = User.find_by(id: params[:id])
        return render_not_found unless student
        return render_forbidden unless can_access_student?(student)

        records = student.attendance_records.includes(:classroom, :teacher, :subject)
        records = records.where(school_id: current_school.id) if current_school
        summary = records.group(:status).count.transform_keys(&:to_s)
        records = records.order(attendance_date: :desc)

        render json: {
          student_id: student.id,
          student_name: student.full_name,
          summary: summary,
          records: records.limit(100).map do |record|
            {
              id: record.id,
              attendance_date: record.attendance_date,
              status: record.status,
              classroom_name: record.classroom.name,
              subject_name: record.subject&.name,
              teacher_name: record.teacher.full_name,
              note: record.note
            }
          end
        }
      end

      private

      def can_access_student?(student)
        return true if current_user.has_role?("admin")
        return true if current_user.id == student.id

        (student.student_classroom_ids & current_user.teaching_classroom_ids).any?
      end
    end
  end
end
