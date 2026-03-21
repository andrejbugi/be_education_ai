class CreateUserInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :user_invitations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :school, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :role_name, null: false
      t.integer :status, null: false, default: 0
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.datetime :last_sent_at, null: false

      t.timestamps
    end

    add_index :user_invitations, :token_digest, unique: true
    add_index :user_invitations, [:user_id, :school_id, :role_name], unique: true, name: "index_user_invitations_on_user_school_role"
  end
end
