module Attendance
  class BulkMark
    Result = Struct.new(:success?, :records, :errors, keyword_init: true)

    def initialize(classroom:, teacher:, school:, attendance_date:, records:, subject: nil)
      @classroom = classroom
      @teacher = teacher
      @school = school
      @attendance_date = attendance_date
      @records = records
      @subject = subject
    end

    def call
      saved_records = []

      AttendanceRecord.transaction do
        records.each do |record_params|
          student = classroom.students.find(record_params[:student_id])
          attendance = AttendanceRecord.find_or_initialize_by(
            school: school,
            classroom: classroom,
            subject: subject,
            student: student,
            attendance_date: attendance_date
          )
          attendance.teacher = teacher
          attendance.status = record_params[:status]
          attendance.note = record_params[:note]
          attendance.save!
          saved_records << attendance
        end
      end

      Result.new(success?: true, records: saved_records, errors: [])
    rescue ActiveRecord::RecordNotFound
      Result.new(success?: false, records: saved_records, errors: ["Student is not enrolled in classroom"])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, records: saved_records, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :classroom, :teacher, :school, :attendance_date, :records, :subject
  end
end
