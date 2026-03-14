class CreateAssignmentStepAnswerKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :assignment_step_answer_keys do |t|
      t.references :assignment_step, null: false, foreign_key: true
      t.text :value, null: false
      t.integer :position, null: false, default: 1
      t.decimal :tolerance, precision: 10, scale: 4
      t.boolean :case_sensitive, null: false, default: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :assignment_step_answer_keys, [:assignment_step_id, :position], unique: true, name: "index_answer_keys_on_step_id_and_position"
  end
end
