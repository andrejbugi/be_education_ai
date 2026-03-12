class CreateEventParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :event_participants do |t|
      t.references :calendar_event, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role
      t.string :attendance_status

      t.timestamps
    end

    add_index :event_participants, [:calendar_event_id, :user_id], unique: true
  end
end
