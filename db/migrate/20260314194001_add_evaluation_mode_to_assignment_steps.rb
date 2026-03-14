class AddEvaluationModeToAssignmentSteps < ActiveRecord::Migration[8.0]
  def change
    add_column :assignment_steps, :evaluation_mode, :string, null: false, default: "manual"
    add_index :assignment_steps, :evaluation_mode
  end
end
