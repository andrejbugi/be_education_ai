class CreateAiMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_messages do |t|
      t.references :ai_session, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.integer :message_type, null: false, default: 0
      t.text :content, null: false
      t.integer :sequence_number, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :ai_messages, [:ai_session_id, :sequence_number], unique: true
    add_index :ai_messages, [:ai_session_id, :created_at]
  end
end
