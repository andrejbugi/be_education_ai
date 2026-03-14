class CreateAssignmentResources < ActiveRecord::Migration[8.0]
  def change
    create_table :assignment_resources do |t|
      t.references :assignment, null: false, foreign_key: true
      t.string :title, null: false
      t.string :resource_type, null: false
      t.string :file_url
      t.string :external_url
      t.string :embed_url
      t.text :description
      t.integer :position, null: false, default: 1
      t.boolean :is_required, null: false, default: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :assignment_resources, [:assignment_id, :position], unique: true
    add_index :assignment_resources, :resource_type
  end
end
