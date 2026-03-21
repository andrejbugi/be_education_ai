class CreateAuthSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :auth_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :current_school, foreign_key: { to_table: :schools }
      t.string :token_digest, null: false
      t.string :ip_address
      t.string :user_agent
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.datetime :last_seen_at

      t.timestamps
    end

    add_index :auth_sessions, :token_digest, unique: true
    add_index :auth_sessions, :expires_at
    add_index :auth_sessions, :revoked_at
  end
end
