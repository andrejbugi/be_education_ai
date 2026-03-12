class CreateSchools < ActiveRecord::Migration[8.0]
  def change
    create_table :schools do |t|
      t.string :name, null: false
      t.string :code
      t.string :city
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :schools, :code, unique: true
  end
end
