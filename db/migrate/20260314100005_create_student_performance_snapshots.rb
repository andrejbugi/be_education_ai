class CreateStudentPerformanceSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :student_performance_snapshots do |t|
      t.references :school, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :classroom, foreign_key: true
      t.integer :period_type, null: false, default: 0
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.decimal :average_grade, precision: 6, scale: 2
      t.integer :completed_assignments_count, null: false, default: 0
      t.integer :in_progress_assignments_count, null: false, default: 0
      t.integer :overdue_assignments_count, null: false, default: 0
      t.integer :missed_assignments_count, null: false, default: 0
      t.decimal :attendance_rate, precision: 6, scale: 2
      t.decimal :engagement_score, precision: 6, scale: 2
      t.jsonb :snapshot_data, null: false, default: {}
      t.datetime :generated_at, null: false

      t.timestamps
    end

    add_index :student_performance_snapshots, [:student_id, :period_type, :period_start], name: "index_performance_snapshots_on_student_period"
    add_index :student_performance_snapshots, [:school_id, :period_type, :period_start], name: "index_performance_snapshots_on_school_period"
    add_index :student_performance_snapshots, [:classroom_id, :period_type, :period_start], name: "index_performance_snapshots_on_classroom_period"
  end
end
