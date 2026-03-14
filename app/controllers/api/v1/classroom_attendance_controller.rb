module Api
  module V1
    class ClassroomAttendanceController < BaseController
      def show
        classroom = Classroom.find_by(id: params[:classroom_id])
        return render_not_found unless classroom
        return render_forbidden unless can_access_classroom?(classroom)

        records = classroom.attendance_records.includes(:student, :teacher, :subject).order(attendance_date: :desc)
        render json: {
          classroom_id: classroom.id,
          classroom_name: classroom.name,
          records: records.limit(100).map do |record|
            {
              id: record.id,
              attendance_date: record.attendance_date,
              status: record.status,
              student_name: record.student.full_name,
              teacher_name: record.teacher.full_name,
              subject_name: record.subject&.name
            }
          end
        }
      end

      private

      def can_access_classroom?(classroom)
        current_user.has_role?("admin") ||
          classroom.teachers.exists?(id: current_user.id) ||
          classroom.students.exists?(id: current_user.id)
      end
    end
  end
end
