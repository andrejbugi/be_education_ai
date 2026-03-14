module Api
  module V1
    class AttendanceRecordsController < BaseController
      def index
        records = AttendanceRecord.includes(:classroom, :student, :teacher, :subject).order(attendance_date: :desc)
        records = records.where(school_id: current_school.id) if current_school
        records = records.where(classroom_id: params[:classroom_id]) if params[:classroom_id].present?
        records = records.where(student_id: params[:student_id]) if params[:student_id].present?
        records = records.where(attendance_date: params[:attendance_date]) if params[:attendance_date].present?
        records = restrict_attendance_scope(records)

        limit, offset = pagination_params
        render json: records.limit(limit).offset(offset).map { |record| serialize_record(record) }
      end

      def create
        require_role!("teacher", "admin")
        return if performed?

        classroom = Classroom.find_by(id: attendance_params[:classroom_id])
        return render_not_found unless classroom
        return render_forbidden unless can_record_attendance?(classroom)

        subject = attendance_params[:subject_id].present? ? Subject.find_by(id: attendance_params[:subject_id]) : nil
        result = Attendance::BulkMark.new(
          classroom: classroom,
          teacher: current_user,
          school: classroom.school,
          attendance_date: attendance_params[:attendance_date],
          subject: subject,
          records: attendance_params[:records].to_a.map { |record| record.to_h.symbolize_keys }
        ).call

        if result.success?
          log_activity(action: "attendance_marked", metadata: { classroom_id: classroom.id, attendance_date: attendance_params[:attendance_date] })
          render json: result.records.map { |record| serialize_record(record) }, status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      def update
        require_role!("teacher", "admin")
        return if performed?

        record = AttendanceRecord.find_by(id: params[:id])
        return render_not_found unless record
        return render_forbidden unless can_record_attendance?(record.classroom)

        if record.update(update_params.merge(teacher: current_user))
          render json: serialize_record(record.reload)
        else
          render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def attendance_params
        params.permit(:classroom_id, :subject_id, :attendance_date, records: %i[student_id status note])
      end

      def update_params
        params.permit(:status, :note)
      end

      def can_record_attendance?(classroom)
        current_user.has_role?("admin") || classroom.teachers.exists?(id: current_user.id)
      end

      def restrict_attendance_scope(records)
        return records if current_user.has_role?("admin")
        return records.where(teacher_id: current_user.id).or(records.where(student_id: current_user.id)) unless current_user.has_role?("student")

        records.where(student_id: current_user.id)
      end

      def serialize_record(record)
        {
          id: record.id,
          school_id: record.school_id,
          classroom: {
            id: record.classroom_id,
            name: record.classroom.name
          },
          subject: record.subject && { id: record.subject_id, name: record.subject.name },
          student: {
            id: record.student_id,
            full_name: record.student.full_name
          },
          teacher: {
            id: record.teacher_id,
            full_name: record.teacher.full_name
          },
          attendance_date: record.attendance_date,
          status: record.status,
          note: record.note
        }
      end
    end
  end
end
