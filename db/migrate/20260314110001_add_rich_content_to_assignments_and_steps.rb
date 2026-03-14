class AddRichContentToAssignmentsAndSteps < ActiveRecord::Migration[8.0]
  def change
    change_table :assignments, bulk: true do |t|
      t.text :teacher_notes
      t.jsonb :content_json, null: false, default: []
    end

    change_table :assignment_steps, bulk: true do |t|
      t.text :prompt
      t.string :resource_url
      t.text :example_answer
      t.jsonb :content_json, null: false, default: []
    end
  end
end
