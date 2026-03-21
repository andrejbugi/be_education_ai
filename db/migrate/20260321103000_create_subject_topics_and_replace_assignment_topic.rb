class CreateSubjectTopicsAndReplaceAssignmentTopic < ActiveRecord::Migration[8.0]
  def up
    create_table :subject_topics do |t|
      t.references :subject, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end

    add_index :subject_topics, [:subject_id, :name], unique: true
    add_reference :assignments, :subject_topic, foreign_key: true

    say_with_time "Backfilling subject topics from assignments.topic" do
      execute <<~SQL.squish
        INSERT INTO subject_topics (subject_id, name, created_at, updated_at)
        SELECT DISTINCT assignments.subject_id, BTRIM(assignments.topic), NOW(), NOW()
        FROM assignments
        WHERE assignments.topic IS NOT NULL
          AND BTRIM(assignments.topic) <> ''
        ON CONFLICT (subject_id, name) DO NOTHING
      SQL

      execute <<~SQL.squish
        UPDATE assignments
        SET subject_topic_id = subject_topics.id
        FROM subject_topics
        WHERE subject_topics.subject_id = assignments.subject_id
          AND subject_topics.name = BTRIM(assignments.topic)
          AND assignments.topic IS NOT NULL
          AND BTRIM(assignments.topic) <> ''
      SQL
    end

    remove_column :assignments, :topic, :string
  end

  def down
    add_column :assignments, :topic, :string

    execute <<~SQL.squish
      UPDATE assignments
      SET topic = subject_topics.name
      FROM subject_topics
      WHERE subject_topics.id = assignments.subject_topic_id
    SQL

    remove_reference :assignments, :subject_topic, foreign_key: true
    drop_table :subject_topics
  end
end
