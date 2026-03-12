class CreateClassrooms < ActiveRecord::Migration[8.0]
  def change
    create_table :classrooms do |t|
      t.references :school, null: false, foreign_key: true
      t.string :name, null: false
      t.string :grade_level
      t.string :academic_year

      t.timestamps
    end

    add_index :classrooms, [:school_id, :name, :academic_year], unique: true
  end
end
