class CreateStudentProgressProfilesAndBadges < ActiveRecord::Migration[8.0]
  def change
    create_table :student_progress_profiles do |t|
      t.references :school, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.integer :total_xp, null: false, default: 0
      t.integer :current_level, null: false, default: 1
      t.integer :current_streak, null: false, default: 0
      t.integer :longest_streak, null: false, default: 0
      t.integer :completed_assignments_count, null: false, default: 0
      t.integer :graded_assignments_count, null: false, default: 0
      t.integer :badges_count, null: false, default: 0
      t.decimal :average_grade, precision: 5, scale: 2
      t.decimal :attendance_rate, precision: 5, scale: 2
      t.date :last_active_on
      t.datetime :last_synced_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :student_progress_profiles, %i[school_id student_id], unique: true

    create_table :student_badges do |t|
      t.references :school, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :student_progress_profile, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.text :description
      t.datetime :awarded_at, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :student_badges, %i[school_id student_id code], unique: true
    add_index :student_badges, %i[student_progress_profile_id awarded_at]
  end
end
