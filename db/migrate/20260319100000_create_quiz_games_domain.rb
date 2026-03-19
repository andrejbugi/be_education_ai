class CreateQuizGamesDomain < ActiveRecord::Migration[8.0]
  def change
    add_column :schools, :settings, :jsonb, null: false, default: {}

    create_table :daily_quiz_questions do |t|
      t.references :school, foreign_key: true
      t.date :quiz_date, null: false
      t.string :title, null: false
      t.text :body, null: false
      t.string :category, null: false
      t.string :difficulty
      t.string :answer_type, null: false, default: "single_choice"
      t.text :correct_answer, null: false
      t.jsonb :answer_options
      t.text :explanation
      t.boolean :is_active, null: false, default: true
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :daily_quiz_questions, %i[school_id quiz_date]
    add_index :daily_quiz_questions, %i[quiz_date is_active]
    add_index :daily_quiz_questions,
              "COALESCE(school_id, 0), quiz_date",
              unique: true,
              where: "is_active = TRUE",
              name: "idx_daily_quiz_questions_unique_active_scope"

    create_table :daily_quiz_answers do |t|
      t.references :school, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :daily_quiz_question, null: false, foreign_key: true
      t.date :quiz_date, null: false
      t.text :selected_answer
      t.text :answer_text
      t.boolean :is_correct, null: false, default: false
      t.datetime :answered_at, null: false
      t.integer :xp_awarded, null: false, default: 0

      t.timestamps
    end

    add_index :daily_quiz_answers, %i[school_id student_id quiz_date], unique: true, name: "idx_daily_quiz_answers_once_per_day"
    add_index :daily_quiz_answers, %i[daily_quiz_question_id answered_at]

    create_table :student_reward_events do |t|
      t.references :school, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.string :source_type, null: false
      t.bigint :source_id, null: false
      t.date :awarded_on, null: false
      t.integer :xp_amount, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :student_reward_events,
              %i[school_id student_id source_type source_id awarded_on],
              unique: true,
              name: "idx_student_reward_events_idempotency"
    add_index :student_reward_events, %i[student_id awarded_on]

    create_table :learning_game_configs do |t|
      t.references :school, foreign_key: true
      t.string :game_key, null: false
      t.string :title, null: false
      t.text :description
      t.string :icon_key
      t.boolean :is_enabled, null: false, default: true
      t.integer :position, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :learning_game_configs, %i[school_id position]
    add_index :learning_game_configs,
              "COALESCE(school_id, 0), game_key",
              unique: true,
              name: "idx_learning_game_configs_unique_scope_key"
  end
end
