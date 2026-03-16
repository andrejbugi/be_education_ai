class CreateChatMessagingTables < ActiveRecord::Migration[8.0]
  def change
    create_table :conversations do |t|
      t.references :school, null: false, foreign_key: true
      t.string :conversation_type, null: false, default: "direct"
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.boolean :active, null: false, default: true
      t.bigint :last_message_id
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :conversations, :conversation_type
    add_index :conversations, :last_message_at

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :body
      t.string :message_type, null: false, default: "text"
      t.string :status, null: false, default: "sent"
      t.bigint :reply_to_message_id
      t.datetime :edited_at
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :messages, %i[conversation_id created_at]
    add_index :messages, :reply_to_message_id
    add_index :messages, :deleted_at
    add_foreign_key :messages, :messages, column: :reply_to_message_id

    create_table :conversation_participants do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :joined_at, null: false
      t.datetime :left_at
      t.bigint :last_read_message_id
      t.datetime :last_read_at
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :conversation_participants, %i[conversation_id user_id], unique: true
    add_foreign_key :conversation_participants, :messages, column: :last_read_message_id

    add_foreign_key :conversations, :messages, column: :last_message_id

    create_table :message_reactions do |t|
      t.references :message, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :reaction, null: false

      t.timestamps
    end

    add_index :message_reactions, %i[message_id user_id reaction], unique: true

    create_table :message_attachments do |t|
      t.references :message, null: false, foreign_key: true
      t.string :attachment_type, null: false, default: "file"
      t.string :file_name
      t.string :content_type
      t.bigint :file_size
      t.string :storage_key
      t.string :file_url

      t.timestamps
    end

    create_table :user_presence_statuses do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :status, null: false, default: "offline"
      t.datetime :last_seen_at, null: false

      t.timestamps
    end

    create_table :message_deliveries do |t|
      t.references :message, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :delivered_at, null: false

      t.timestamps
    end

    add_index :message_deliveries, %i[message_id user_id], unique: true

    create_table :message_reads do |t|
      t.references :message, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :read_at, null: false

      t.timestamps
    end

    add_index :message_reads, %i[message_id user_id], unique: true
  end
end
