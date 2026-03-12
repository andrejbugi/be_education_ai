class CreateCalendarEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :calendar_events do |t|
      t.references :school, null: false, foreign_key: true
      t.references :assignment, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :event_type, null: false, default: "general"
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.boolean :all_day, null: false, default: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :calendar_events, [:school_id, :starts_at]
  end
end
