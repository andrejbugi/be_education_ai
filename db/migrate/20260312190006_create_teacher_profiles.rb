class CreateTeacherProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :teacher_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :school, foreign_key: true
      t.string :title
      t.text :bio

      t.timestamps
    end
  end
end
