class CreateClassroomUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :classroom_users do |t|
      t.references :classroom, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :joined_at

      t.timestamps
    end

    add_index :classroom_users, [:classroom_id, :user_id], unique: true
  end
end
