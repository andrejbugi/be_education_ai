class CreateGrades < ActiveRecord::Migration[8.0]
  def change
    create_table :grades do |t|
      t.references :submission, null: false, foreign_key: true
      t.references :teacher, null: false, foreign_key: { to_table: :users }
      t.decimal :score, precision: 6, scale: 2, null: false
      t.decimal :max_score, precision: 6, scale: 2
      t.text :feedback
      t.datetime :graded_at, null: false

      t.timestamps
    end
  end
end
