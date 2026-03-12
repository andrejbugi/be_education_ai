class CreateTeacherClassrooms < ActiveRecord::Migration[8.0]
  def change
    create_table :teacher_classrooms do |t|
      t.references :classroom, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :homeroom, null: false, default: false

      t.timestamps
    end

    add_index :teacher_classrooms, [:classroom_id, :user_id], unique: true
  end
end
