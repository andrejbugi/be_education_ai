class AddRoomFieldsToClassroomsSubjectsAndTeacherProfiles < ActiveRecord::Migration[8.0]
  def change
    change_table :classrooms, bulk: true do |t|
      t.string :room_name
      t.string :room_label
    end

    change_table :subjects, bulk: true do |t|
      t.string :room_name
      t.string :room_label
    end

    change_table :teacher_profiles, bulk: true do |t|
      t.string :room_name
      t.string :room_label
    end
  end
end
