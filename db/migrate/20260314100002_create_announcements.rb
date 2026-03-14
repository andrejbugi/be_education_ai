class CreateAnnouncements < ActiveRecord::Migration[8.0]
  def change
    create_table :announcements do |t|
      t.references :school, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.references :classroom, foreign_key: true
      t.references :subject, foreign_key: true
      t.string :title, null: false
      t.text :body, null: false
      t.integer :status, null: false, default: 0
      t.datetime :published_at
      t.datetime :starts_at
      t.datetime :ends_at
      t.integer :priority, null: false, default: 0
      t.string :audience_type, null: false, default: "school"

      t.timestamps
    end

    add_index :announcements, [:school_id, :published_at]
    add_index :announcements, [:classroom_id, :published_at]
    add_index :announcements, [:subject_id, :published_at]
    add_index :announcements, :status
  end
end
