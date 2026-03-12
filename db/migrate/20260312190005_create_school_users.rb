class CreateSchoolUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :school_users do |t|
      t.references :school, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :joined_at

      t.timestamps
    end

    add_index :school_users, [:school_id, :user_id], unique: true
  end
end
