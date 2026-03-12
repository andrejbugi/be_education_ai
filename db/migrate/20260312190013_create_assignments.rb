class CreateAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :assignments do |t|
      t.references :subject, null: false, foreign_key: true
      t.references :classroom, null: false, foreign_key: true
      t.references :teacher, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.string :assignment_type, null: false, default: "homework"
      t.integer :status, null: false, default: 0
      t.datetime :due_at
      t.datetime :published_at
      t.integer :max_points
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end

    add_index :assignments, [:classroom_id, :subject_id, :due_at]
  end
end
