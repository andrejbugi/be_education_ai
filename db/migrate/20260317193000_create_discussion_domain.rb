class CreateDiscussionDomain < ActiveRecord::Migration[8.0]
  def change
    create_table :discussion_spaces do |t|
      t.references :school, null: false, foreign_key: true
      t.string :space_type, null: false
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "active"
      t.string :visibility, null: false, default: "students_and_teachers"
      t.references :assignment, foreign_key: true
      t.references :classroom, foreign_key: true
      t.references :subject, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :discussion_spaces, :space_type
    add_index :discussion_spaces, %i[school_id space_type]
    add_index :discussion_spaces, %i[space_type assignment_id], unique: true, where: "assignment_id IS NOT NULL", name: "index_discussion_spaces_on_assignment_scope"
    add_index :discussion_spaces, %i[space_type classroom_id], unique: true, where: "classroom_id IS NOT NULL", name: "index_discussion_spaces_on_classroom_scope"
    add_index :discussion_spaces, %i[space_type subject_id], unique: true, where: "subject_id IS NOT NULL", name: "index_discussion_spaces_on_subject_scope"

    create_table :discussion_threads do |t|
      t.references :discussion_space, null: false, foreign_key: true
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :body, null: false
      t.string :status, null: false, default: "active"
      t.boolean :pinned, null: false, default: false
      t.boolean :locked, null: false, default: false
      t.integer :posts_count, null: false, default: 0
      t.datetime :last_post_at

      t.timestamps
    end

    add_index :discussion_threads, %i[discussion_space_id pinned]
    add_index :discussion_threads, %i[discussion_space_id updated_at]
    add_index :discussion_threads, %i[discussion_space_id last_post_at]

    create_table :discussion_posts do |t|
      t.references :discussion_thread, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.bigint :parent_post_id
      t.text :body, null: false
      t.string :status, null: false, default: "visible"
      t.datetime :edited_at
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :discussion_posts, :parent_post_id
    add_index :discussion_posts, %i[discussion_thread_id created_at]
    add_index :discussion_posts, %i[discussion_thread_id parent_post_id]
    add_foreign_key :discussion_posts, :discussion_posts, column: :parent_post_id
  end
end
