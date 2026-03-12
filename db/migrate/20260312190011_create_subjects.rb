class CreateSubjects < ActiveRecord::Migration[8.0]
  def change
    create_table :subjects do |t|
      t.references :school, null: false, foreign_key: true
      t.string :name, null: false
      t.string :code

      t.timestamps
    end

    add_index :subjects, [:school_id, :name], unique: true
  end
end
