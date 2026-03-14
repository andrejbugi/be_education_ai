class AddAttendanceUniqueIndex < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      CREATE UNIQUE INDEX index_attendance_records_on_student_classroom_subject_date
      ON attendance_records (student_id, classroom_id, COALESCE(subject_id, 0), attendance_date);
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX index_attendance_records_on_student_classroom_subject_date;
    SQL
  end
end
