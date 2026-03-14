class CreateAttendanceRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_records do |t|
      t.references :school, null: false, foreign_key: true
      t.references :classroom, null: false, foreign_key: true
      t.references :subject, foreign_key: true
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :teacher, null: false, foreign_key: { to_table: :users }
      t.date :attendance_date, null: false
      t.integer :status, null: false, default: 0
      t.text :note

      t.timestamps
    end

    add_index :attendance_records, [:classroom_id, :attendance_date]
    add_index :attendance_records, [:student_id, :attendance_date]
  end
end
