class CreateTeacherSubjects < ActiveRecord::Migration[8.0]
  def change
    create_table :teacher_subjects do |t|
      t.references :teacher, null: false, foreign_key: { to_table: :users }
      t.references :subject, null: false, foreign_key: true

      t.timestamps
    end

    add_index :teacher_subjects, [:teacher_id, :subject_id], unique: true
  end
end
