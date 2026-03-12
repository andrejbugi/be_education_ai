class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.references :commentable, polymorphic: true, null: false
      t.text :body, null: false
      t.string :visibility, null: false, default: "all"

      t.timestamps
    end
  end
end
