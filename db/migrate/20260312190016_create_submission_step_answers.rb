class CreateSubmissionStepAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :submission_step_answers do |t|
      t.references :submission, null: false, foreign_key: true
      t.references :assignment_step, null: false, foreign_key: true
      t.text :answer_text
      t.jsonb :answer_data, null: false, default: {}
      t.integer :status, null: false, default: 0
      t.datetime :answered_at

      t.timestamps
    end

    add_index :submission_step_answers, [:submission_id, :assignment_step_id], unique: true
  end
end
