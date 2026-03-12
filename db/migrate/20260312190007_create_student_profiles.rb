class CreateStudentProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :student_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :school, foreign_key: true
      t.string :student_number
      t.string :grade_level
      t.string :guardian_name
      t.string :guardian_phone

      t.timestamps
    end
  end
end
