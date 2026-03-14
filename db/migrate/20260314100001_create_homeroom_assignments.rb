class CreateHomeroomAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :homeroom_assignments do |t|
      t.references :school, null: false, foreign_key: true
      t.references :classroom, null: false, foreign_key: true
      t.references :teacher, null: false, foreign_key: { to_table: :users }
      t.boolean :active, null: false, default: true
      t.date :starts_on, null: false
      t.date :ends_on

      t.timestamps
    end

    add_index :homeroom_assignments,
              :classroom_id,
              unique: true,
              where: "active = true",
              name: "index_homeroom_assignments_on_classroom_id_active_unique"
  end
end
