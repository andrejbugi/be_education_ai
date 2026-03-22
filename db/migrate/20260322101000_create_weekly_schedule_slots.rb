class CreateWeeklyScheduleSlots < ActiveRecord::Migration[8.0]
  def change
    create_table :weekly_schedule_slots do |t|
      t.references :school, null: false, foreign_key: true
      t.references :classroom, null: false, foreign_key: true
      t.references :subject, null: false, foreign_key: true
      t.references :teacher, null: false, foreign_key: { to_table: :users }
      t.integer :day_of_week, null: false
      t.integer :period_number, null: false
      t.string :room_name
      t.string :room_label

      t.timestamps
    end

    add_index :weekly_schedule_slots, [:classroom_id, :day_of_week, :period_number], unique: true, name: "idx_weekly_schedule_slots_on_classroom_day_period"
    add_index :weekly_schedule_slots, [:teacher_id, :day_of_week, :period_number], name: "idx_weekly_schedule_slots_on_teacher_day_period"
    add_index :weekly_schedule_slots, [:school_id, :day_of_week], name: "idx_weekly_schedule_slots_on_school_day"
  end
end
