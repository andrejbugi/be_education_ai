class CreateAiSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_sessions do |t|
      t.references :school, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :assignment, foreign_key: true
      t.references :submission, foreign_key: true
      t.references :subject, foreign_key: true
      t.string :title
      t.integer :session_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.datetime :started_at, null: false
      t.datetime :last_activity_at, null: false
      t.datetime :ended_at
      t.jsonb :context_data, null: false, default: {}

      t.timestamps
    end

    add_index :ai_sessions, [:user_id, :status, :last_activity_at]
  end
end
