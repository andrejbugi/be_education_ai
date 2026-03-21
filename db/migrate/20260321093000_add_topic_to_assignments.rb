class AddTopicToAssignments < ActiveRecord::Migration[8.0]
  def change
    add_column :assignments, :topic, :string
  end
end
