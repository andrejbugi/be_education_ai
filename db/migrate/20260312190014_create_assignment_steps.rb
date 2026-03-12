class CreateAssignmentSteps < ActiveRecord::Migration[8.0]
  def change
    create_table :assignment_steps do |t|
      t.references :assignment, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :title
      t.text :content
      t.string :step_type, null: false, default: "text"
      t.boolean :required, null: false, default: true
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :assignment_steps, [:assignment_id, :position], unique: true
  end
end
