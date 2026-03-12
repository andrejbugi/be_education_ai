class CreateSubmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :submissions do |t|
      t.references :assignment, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0
      t.datetime :started_at
      t.datetime :submitted_at
      t.datetime :reviewed_at
      t.boolean :late, null: false, default: false
      t.decimal :total_score, precision: 6, scale: 2
      t.text :feedback

      t.timestamps
    end

    add_index :submissions, [:assignment_id, :student_id], unique: true
  end
end
