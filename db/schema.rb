# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_03_21_103000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "action", null: false
    t.string "trackable_type"
    t.bigint "trackable_id"
    t.datetime "occurred_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["trackable_type", "trackable_id"], name: "index_activity_logs_on_trackable"
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
  end

  create_table "ai_messages", force: :cascade do |t|
    t.bigint "ai_session_id", null: false
    t.integer "role", default: 0, null: false
    t.integer "message_type", default: 0, null: false
    t.text "content", null: false
    t.integer "sequence_number", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ai_session_id", "created_at"], name: "index_ai_messages_on_ai_session_id_and_created_at"
    t.index ["ai_session_id", "sequence_number"], name: "index_ai_messages_on_ai_session_id_and_sequence_number", unique: true
    t.index ["ai_session_id"], name: "index_ai_messages_on_ai_session_id"
  end

  create_table "ai_sessions", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "user_id", null: false
    t.bigint "assignment_id"
    t.bigint "submission_id"
    t.bigint "subject_id"
    t.string "title"
    t.integer "session_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "started_at", null: false
    t.datetime "last_activity_at", null: false
    t.datetime "ended_at"
    t.jsonb "context_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "index_ai_sessions_on_assignment_id"
    t.index ["school_id"], name: "index_ai_sessions_on_school_id"
    t.index ["subject_id"], name: "index_ai_sessions_on_subject_id"
    t.index ["submission_id"], name: "index_ai_sessions_on_submission_id"
    t.index ["user_id", "status", "last_activity_at"], name: "index_ai_sessions_on_user_id_and_status_and_last_activity_at"
    t.index ["user_id"], name: "index_ai_sessions_on_user_id"
  end

  create_table "announcements", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "author_id", null: false
    t.bigint "classroom_id"
    t.bigint "subject_id"
    t.string "title", null: false
    t.text "body", null: false
    t.integer "status", default: 0, null: false
    t.datetime "published_at"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.integer "priority", default: 0, null: false
    t.string "audience_type", default: "school", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_announcements_on_author_id"
    t.index ["classroom_id", "published_at"], name: "index_announcements_on_classroom_id_and_published_at"
    t.index ["classroom_id"], name: "index_announcements_on_classroom_id"
    t.index ["school_id", "published_at"], name: "index_announcements_on_school_id_and_published_at"
    t.index ["school_id"], name: "index_announcements_on_school_id"
    t.index ["status"], name: "index_announcements_on_status"
    t.index ["subject_id", "published_at"], name: "index_announcements_on_subject_id_and_published_at"
    t.index ["subject_id"], name: "index_announcements_on_subject_id"
  end

  create_table "assignment_resources", force: :cascade do |t|
    t.bigint "assignment_id", null: false
    t.string "title", null: false
    t.string "resource_type", null: false
    t.string "file_url"
    t.string "external_url"
    t.string "embed_url"
    t.text "description"
    t.integer "position", default: 1, null: false
    t.boolean "is_required", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id", "position"], name: "index_assignment_resources_on_assignment_id_and_position", unique: true
    t.index ["assignment_id"], name: "index_assignment_resources_on_assignment_id"
    t.index ["resource_type"], name: "index_assignment_resources_on_resource_type"
  end

  create_table "assignment_step_answer_keys", force: :cascade do |t|
    t.bigint "assignment_step_id", null: false
    t.text "value", null: false
    t.integer "position", default: 1, null: false
    t.decimal "tolerance", precision: 10, scale: 4
    t.boolean "case_sensitive", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_step_id", "position"], name: "index_answer_keys_on_step_id_and_position", unique: true
    t.index ["assignment_step_id"], name: "index_assignment_step_answer_keys_on_assignment_step_id"
  end

  create_table "assignment_steps", force: :cascade do |t|
    t.bigint "assignment_id", null: false
    t.integer "position", null: false
    t.string "title"
    t.text "content"
    t.string "step_type", default: "text", null: false
    t.boolean "required", default: true, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "prompt"
    t.string "resource_url"
    t.text "example_answer"
    t.jsonb "content_json", default: [], null: false
    t.string "evaluation_mode", default: "manual", null: false
    t.index ["assignment_id", "position"], name: "index_assignment_steps_on_assignment_id_and_position", unique: true
    t.index ["assignment_id"], name: "index_assignment_steps_on_assignment_id"
    t.index ["evaluation_mode"], name: "index_assignment_steps_on_evaluation_mode"
  end

  create_table "assignments", force: :cascade do |t|
    t.bigint "subject_id", null: false
    t.bigint "classroom_id", null: false
    t.bigint "teacher_id", null: false
    t.string "title", null: false
    t.text "description"
    t.string "assignment_type", default: "homework", null: false
    t.integer "status", default: 0, null: false
    t.datetime "due_at"
    t.datetime "published_at"
    t.integer "max_points"
    t.jsonb "settings", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "teacher_notes"
    t.jsonb "content_json", default: [], null: false
    t.bigint "subject_topic_id"
    t.index ["classroom_id", "subject_id", "due_at"], name: "index_assignments_on_classroom_id_and_subject_id_and_due_at"
    t.index ["classroom_id"], name: "index_assignments_on_classroom_id"
    t.index ["subject_id"], name: "index_assignments_on_subject_id"
    t.index ["subject_topic_id"], name: "index_assignments_on_subject_topic_id"
    t.index ["teacher_id"], name: "index_assignments_on_teacher_id"
  end

  create_table "attendance_records", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "classroom_id", null: false
    t.bigint "subject_id"
    t.bigint "student_id", null: false
    t.bigint "teacher_id", null: false
    t.date "attendance_date", null: false
    t.integer "status", default: 0, null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "student_id, classroom_id, COALESCE(subject_id, (0)::bigint), attendance_date", name: "index_attendance_records_on_student_classroom_subject_date", unique: true
    t.index ["classroom_id", "attendance_date"], name: "index_attendance_records_on_classroom_id_and_attendance_date"
    t.index ["classroom_id"], name: "index_attendance_records_on_classroom_id"
    t.index ["school_id"], name: "index_attendance_records_on_school_id"
    t.index ["student_id", "attendance_date"], name: "index_attendance_records_on_student_id_and_attendance_date"
    t.index ["student_id"], name: "index_attendance_records_on_student_id"
    t.index ["subject_id"], name: "index_attendance_records_on_subject_id"
    t.index ["teacher_id"], name: "index_attendance_records_on_teacher_id"
  end

  create_table "calendar_events", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "assignment_id"
    t.string "title", null: false
    t.text "description"
    t.string "event_type", default: "general", null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at"
    t.boolean "all_day", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "index_calendar_events_on_assignment_id"
    t.index ["school_id", "starts_at"], name: "index_calendar_events_on_school_id_and_starts_at"
    t.index ["school_id"], name: "index_calendar_events_on_school_id"
  end

  create_table "classroom_users", force: :cascade do |t|
    t.bigint "classroom_id", null: false
    t.bigint "user_id", null: false
    t.datetime "joined_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id", "user_id"], name: "index_classroom_users_on_classroom_id_and_user_id", unique: true
    t.index ["classroom_id"], name: "index_classroom_users_on_classroom_id"
    t.index ["user_id"], name: "index_classroom_users_on_user_id"
  end

  create_table "classrooms", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "name", null: false
    t.string "grade_level"
    t.string "academic_year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "name", "academic_year"], name: "index_classrooms_on_school_id_and_name_and_academic_year", unique: true
    t.index ["school_id"], name: "index_classrooms_on_school_id"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.string "commentable_type", null: false
    t.bigint "commentable_id", null: false
    t.text "body", null: false
    t.string "visibility", default: "all", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
  end

  create_table "conversation_participants", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.bigint "user_id", null: false
    t.datetime "joined_at", null: false
    t.datetime "left_at"
    t.bigint "last_read_message_id"
    t.datetime "last_read_at"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "user_id"], name: "index_conversation_participants_on_conversation_id_and_user_id", unique: true
    t.index ["conversation_id"], name: "index_conversation_participants_on_conversation_id"
    t.index ["user_id"], name: "index_conversation_participants_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "conversation_type", default: "direct", null: false
    t.bigint "created_by_id", null: false
    t.boolean "active", default: true, null: false
    t.bigint "last_message_id"
    t.datetime "last_message_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_type"], name: "index_conversations_on_conversation_type"
    t.index ["created_by_id"], name: "index_conversations_on_created_by_id"
    t.index ["last_message_at"], name: "index_conversations_on_last_message_at"
    t.index ["school_id"], name: "index_conversations_on_school_id"
  end

  create_table "daily_quiz_answers", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "student_id", null: false
    t.bigint "daily_quiz_question_id", null: false
    t.date "quiz_date", null: false
    t.text "selected_answer"
    t.text "answer_text"
    t.boolean "is_correct", default: false, null: false
    t.datetime "answered_at", null: false
    t.integer "xp_awarded", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["daily_quiz_question_id", "answered_at"], name: "idx_on_daily_quiz_question_id_answered_at_86b03cd471"
    t.index ["daily_quiz_question_id"], name: "index_daily_quiz_answers_on_daily_quiz_question_id"
    t.index ["school_id", "student_id", "quiz_date"], name: "idx_daily_quiz_answers_once_per_day", unique: true
    t.index ["school_id"], name: "index_daily_quiz_answers_on_school_id"
    t.index ["student_id"], name: "index_daily_quiz_answers_on_student_id"
  end

  create_table "daily_quiz_questions", force: :cascade do |t|
    t.bigint "school_id"
    t.date "quiz_date", null: false
    t.string "title", null: false
    t.text "body", null: false
    t.string "category", null: false
    t.string "difficulty"
    t.string "answer_type", default: "single_choice", null: false
    t.text "correct_answer", null: false
    t.jsonb "answer_options"
    t.text "explanation"
    t.boolean "is_active", default: true, null: false
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "COALESCE(school_id, (0)::bigint), quiz_date", name: "idx_daily_quiz_questions_unique_active_scope", unique: true, where: "(is_active = true)"
    t.index ["created_by_id"], name: "index_daily_quiz_questions_on_created_by_id"
    t.index ["quiz_date", "is_active"], name: "index_daily_quiz_questions_on_quiz_date_and_is_active"
    t.index ["school_id", "quiz_date"], name: "index_daily_quiz_questions_on_school_id_and_quiz_date"
    t.index ["school_id"], name: "index_daily_quiz_questions_on_school_id"
  end

  create_table "discussion_posts", force: :cascade do |t|
    t.bigint "discussion_thread_id", null: false
    t.bigint "author_id", null: false
    t.bigint "parent_post_id"
    t.text "body", null: false
    t.string "status", default: "visible", null: false
    t.datetime "edited_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_discussion_posts_on_author_id"
    t.index ["discussion_thread_id", "created_at"], name: "index_discussion_posts_on_discussion_thread_id_and_created_at"
    t.index ["discussion_thread_id", "parent_post_id"], name: "idx_on_discussion_thread_id_parent_post_id_2d40aeeee6"
    t.index ["discussion_thread_id"], name: "index_discussion_posts_on_discussion_thread_id"
    t.index ["parent_post_id"], name: "index_discussion_posts_on_parent_post_id"
  end

  create_table "discussion_spaces", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "space_type", null: false
    t.string "title", null: false
    t.text "description"
    t.string "status", default: "active", null: false
    t.string "visibility", default: "students_and_teachers", null: false
    t.bigint "assignment_id"
    t.bigint "classroom_id"
    t.bigint "subject_id"
    t.bigint "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "index_discussion_spaces_on_assignment_id"
    t.index ["classroom_id"], name: "index_discussion_spaces_on_classroom_id"
    t.index ["created_by_id"], name: "index_discussion_spaces_on_created_by_id"
    t.index ["school_id", "space_type"], name: "index_discussion_spaces_on_school_id_and_space_type"
    t.index ["school_id"], name: "index_discussion_spaces_on_school_id"
    t.index ["space_type", "assignment_id"], name: "index_discussion_spaces_on_assignment_scope", unique: true, where: "(assignment_id IS NOT NULL)"
    t.index ["space_type", "classroom_id"], name: "index_discussion_spaces_on_classroom_scope", unique: true, where: "(classroom_id IS NOT NULL)"
    t.index ["space_type", "subject_id"], name: "index_discussion_spaces_on_subject_scope", unique: true, where: "(subject_id IS NOT NULL)"
    t.index ["space_type"], name: "index_discussion_spaces_on_space_type"
    t.index ["subject_id"], name: "index_discussion_spaces_on_subject_id"
  end

  create_table "discussion_threads", force: :cascade do |t|
    t.bigint "discussion_space_id", null: false
    t.bigint "creator_id", null: false
    t.string "title", null: false
    t.text "body", null: false
    t.string "status", default: "active", null: false
    t.boolean "pinned", default: false, null: false
    t.boolean "locked", default: false, null: false
    t.integer "posts_count", default: 0, null: false
    t.datetime "last_post_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_discussion_threads_on_creator_id"
    t.index ["discussion_space_id", "last_post_at"], name: "idx_on_discussion_space_id_last_post_at_8a04856071"
    t.index ["discussion_space_id", "pinned"], name: "index_discussion_threads_on_discussion_space_id_and_pinned"
    t.index ["discussion_space_id", "updated_at"], name: "index_discussion_threads_on_discussion_space_id_and_updated_at"
    t.index ["discussion_space_id"], name: "index_discussion_threads_on_discussion_space_id"
  end

  create_table "event_participants", force: :cascade do |t|
    t.bigint "calendar_event_id", null: false
    t.bigint "user_id", null: false
    t.string "role"
    t.string "attendance_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["calendar_event_id", "user_id"], name: "index_event_participants_on_calendar_event_id_and_user_id", unique: true
    t.index ["calendar_event_id"], name: "index_event_participants_on_calendar_event_id"
    t.index ["user_id"], name: "index_event_participants_on_user_id"
  end

  create_table "grades", force: :cascade do |t|
    t.bigint "submission_id", null: false
    t.bigint "teacher_id", null: false
    t.decimal "score", precision: 6, scale: 2, null: false
    t.decimal "max_score", precision: 6, scale: 2
    t.text "feedback"
    t.datetime "graded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["submission_id"], name: "index_grades_on_submission_id"
    t.index ["teacher_id"], name: "index_grades_on_teacher_id"
  end

  create_table "homeroom_assignments", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "classroom_id", null: false
    t.bigint "teacher_id", null: false
    t.boolean "active", default: true, null: false
    t.date "starts_on", null: false
    t.date "ends_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id"], name: "index_homeroom_assignments_on_classroom_id"
    t.index ["classroom_id"], name: "index_homeroom_assignments_on_classroom_id_active_unique", unique: true, where: "(active = true)"
    t.index ["school_id"], name: "index_homeroom_assignments_on_school_id"
    t.index ["teacher_id"], name: "index_homeroom_assignments_on_teacher_id"
  end

  create_table "learning_game_configs", force: :cascade do |t|
    t.bigint "school_id"
    t.string "game_key", null: false
    t.string "title", null: false
    t.text "description"
    t.string "icon_key"
    t.boolean "is_enabled", default: true, null: false
    t.integer "position", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "COALESCE(school_id, (0)::bigint), game_key", name: "idx_learning_game_configs_unique_scope_key", unique: true
    t.index ["school_id", "position"], name: "index_learning_game_configs_on_school_id_and_position"
    t.index ["school_id"], name: "index_learning_game_configs_on_school_id"
  end

  create_table "message_attachments", force: :cascade do |t|
    t.bigint "message_id", null: false
    t.string "attachment_type", default: "file", null: false
    t.string "file_name"
    t.string "content_type"
    t.bigint "file_size"
    t.string "storage_key"
    t.string "file_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_message_attachments_on_message_id"
  end

  create_table "message_deliveries", force: :cascade do |t|
    t.bigint "message_id", null: false
    t.bigint "user_id", null: false
    t.datetime "delivered_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "user_id"], name: "index_message_deliveries_on_message_id_and_user_id", unique: true
    t.index ["message_id"], name: "index_message_deliveries_on_message_id"
    t.index ["user_id"], name: "index_message_deliveries_on_user_id"
  end

  create_table "message_reactions", force: :cascade do |t|
    t.bigint "message_id", null: false
    t.bigint "user_id", null: false
    t.string "reaction", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "user_id", "reaction"], name: "index_message_reactions_on_message_id_and_user_id_and_reaction", unique: true
    t.index ["message_id"], name: "index_message_reactions_on_message_id"
    t.index ["user_id"], name: "index_message_reactions_on_user_id"
  end

  create_table "message_reads", force: :cascade do |t|
    t.bigint "message_id", null: false
    t.bigint "user_id", null: false
    t.datetime "read_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "user_id"], name: "index_message_reads_on_message_id_and_user_id", unique: true
    t.index ["message_id"], name: "index_message_reads_on_message_id"
    t.index ["user_id"], name: "index_message_reads_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.bigint "sender_id", null: false
    t.text "body"
    t.string "message_type", default: "text", null: false
    t.string "status", default: "sent", null: false
    t.bigint "reply_to_message_id"
    t.datetime "edited_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["deleted_at"], name: "index_messages_on_deleted_at"
    t.index ["reply_to_message_id"], name: "index_messages_on_reply_to_message_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "actor_id"
    t.string "notification_type", null: false
    t.string "title"
    t.text "body"
    t.datetime "read_at"
    t.jsonb "payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "school_users", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "user_id", null: false
    t.datetime "joined_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "user_id"], name: "index_school_users_on_school_id_and_user_id", unique: true
    t.index ["school_id"], name: "index_school_users_on_school_id"
    t.index ["user_id"], name: "index_school_users_on_user_id"
  end

  create_table "schools", force: :cascade do |t|
    t.string "name", null: false
    t.string "code"
    t.string "city"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "settings", default: {}, null: false
    t.index ["code"], name: "index_schools_on_code", unique: true
  end

  create_table "student_badges", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "student_id", null: false
    t.bigint "student_progress_profile_id", null: false
    t.string "code", null: false
    t.string "name", null: false
    t.text "description"
    t.datetime "awarded_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "student_id", "code"], name: "index_student_badges_on_school_id_and_student_id_and_code", unique: true
    t.index ["school_id"], name: "index_student_badges_on_school_id"
    t.index ["student_id"], name: "index_student_badges_on_student_id"
    t.index ["student_progress_profile_id", "awarded_at"], name: "idx_on_student_progress_profile_id_awarded_at_c30b442be2"
    t.index ["student_progress_profile_id"], name: "index_student_badges_on_student_progress_profile_id"
  end

  create_table "student_performance_snapshots", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "student_id", null: false
    t.bigint "classroom_id"
    t.integer "period_type", default: 0, null: false
    t.date "period_start", null: false
    t.date "period_end", null: false
    t.decimal "average_grade", precision: 6, scale: 2
    t.integer "completed_assignments_count", default: 0, null: false
    t.integer "in_progress_assignments_count", default: 0, null: false
    t.integer "overdue_assignments_count", default: 0, null: false
    t.integer "missed_assignments_count", default: 0, null: false
    t.decimal "attendance_rate", precision: 6, scale: 2
    t.decimal "engagement_score", precision: 6, scale: 2
    t.jsonb "snapshot_data", default: {}, null: false
    t.datetime "generated_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id", "period_type", "period_start"], name: "index_performance_snapshots_on_classroom_period"
    t.index ["classroom_id"], name: "index_student_performance_snapshots_on_classroom_id"
    t.index ["school_id", "period_type", "period_start"], name: "index_performance_snapshots_on_school_period"
    t.index ["school_id"], name: "index_student_performance_snapshots_on_school_id"
    t.index ["student_id", "period_type", "period_start"], name: "index_performance_snapshots_on_student_period"
    t.index ["student_id"], name: "index_student_performance_snapshots_on_student_id"
  end

  create_table "student_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "school_id"
    t.string "student_number"
    t.string "grade_level"
    t.string "guardian_name"
    t.string "guardian_phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_student_profiles_on_school_id"
    t.index ["user_id"], name: "index_student_profiles_on_user_id", unique: true
  end

  create_table "student_progress_profiles", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "student_id", null: false
    t.integer "total_xp", default: 0, null: false
    t.integer "current_level", default: 1, null: false
    t.integer "current_streak", default: 0, null: false
    t.integer "longest_streak", default: 0, null: false
    t.integer "completed_assignments_count", default: 0, null: false
    t.integer "graded_assignments_count", default: 0, null: false
    t.integer "badges_count", default: 0, null: false
    t.decimal "average_grade", precision: 5, scale: 2
    t.decimal "attendance_rate", precision: 5, scale: 2
    t.date "last_active_on"
    t.datetime "last_synced_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "student_id"], name: "index_student_progress_profiles_on_school_id_and_student_id", unique: true
    t.index ["school_id"], name: "index_student_progress_profiles_on_school_id"
    t.index ["student_id"], name: "index_student_progress_profiles_on_student_id"
  end

  create_table "student_reward_events", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "student_id", null: false
    t.string "source_type", null: false
    t.bigint "source_id", null: false
    t.date "awarded_on", null: false
    t.integer "xp_amount", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "student_id", "source_type", "source_id", "awarded_on"], name: "idx_student_reward_events_idempotency", unique: true
    t.index ["school_id"], name: "index_student_reward_events_on_school_id"
    t.index ["student_id", "awarded_on"], name: "index_student_reward_events_on_student_id_and_awarded_on"
    t.index ["student_id"], name: "index_student_reward_events_on_student_id"
  end

  create_table "subject_topics", force: :cascade do |t|
    t.bigint "subject_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subject_id", "name"], name: "index_subject_topics_on_subject_id_and_name", unique: true
    t.index ["subject_id"], name: "index_subject_topics_on_subject_id"
  end

  create_table "subjects", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "name", null: false
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "name"], name: "index_subjects_on_school_id_and_name", unique: true
    t.index ["school_id"], name: "index_subjects_on_school_id"
  end

  create_table "submission_step_answers", force: :cascade do |t|
    t.bigint "submission_id", null: false
    t.bigint "assignment_step_id", null: false
    t.text "answer_text"
    t.jsonb "answer_data", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.datetime "answered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_step_id"], name: "index_submission_step_answers_on_assignment_step_id"
    t.index ["submission_id", "assignment_step_id"], name: "idx_on_submission_id_assignment_step_id_88f08f04b8", unique: true
    t.index ["submission_id"], name: "index_submission_step_answers_on_submission_id"
  end

  create_table "submissions", force: :cascade do |t|
    t.bigint "assignment_id", null: false
    t.bigint "student_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "started_at"
    t.datetime "submitted_at"
    t.datetime "reviewed_at"
    t.boolean "late", default: false, null: false
    t.decimal "total_score", precision: 6, scale: 2
    t.text "feedback"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id", "student_id"], name: "index_submissions_on_assignment_id_and_student_id", unique: true
    t.index ["assignment_id"], name: "index_submissions_on_assignment_id"
    t.index ["student_id"], name: "index_submissions_on_student_id"
  end

  create_table "teacher_classrooms", force: :cascade do |t|
    t.bigint "classroom_id", null: false
    t.bigint "user_id", null: false
    t.boolean "homeroom", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id", "user_id"], name: "index_teacher_classrooms_on_classroom_id_and_user_id", unique: true
    t.index ["classroom_id"], name: "index_teacher_classrooms_on_classroom_id"
    t.index ["user_id"], name: "index_teacher_classrooms_on_user_id"
  end

  create_table "teacher_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "school_id"
    t.string "title"
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_teacher_profiles_on_school_id"
    t.index ["user_id"], name: "index_teacher_profiles_on_user_id", unique: true
  end

  create_table "teacher_subjects", force: :cascade do |t|
    t.bigint "teacher_id", null: false
    t.bigint "subject_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subject_id"], name: "index_teacher_subjects_on_subject_id"
    t.index ["teacher_id", "subject_id"], name: "index_teacher_subjects_on_teacher_id_and_subject_id", unique: true
    t.index ["teacher_id"], name: "index_teacher_subjects_on_teacher_id"
  end

  create_table "user_presence_statuses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "status", default: "offline", null: false
    t.datetime "last_seen_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_presence_statuses_on_user_id", unique: true
  end

  create_table "user_roles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "locale", default: "mk", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_logs", "users"
  add_foreign_key "ai_messages", "ai_sessions"
  add_foreign_key "ai_sessions", "assignments"
  add_foreign_key "ai_sessions", "schools"
  add_foreign_key "ai_sessions", "subjects"
  add_foreign_key "ai_sessions", "submissions"
  add_foreign_key "ai_sessions", "users"
  add_foreign_key "announcements", "classrooms"
  add_foreign_key "announcements", "schools"
  add_foreign_key "announcements", "subjects"
  add_foreign_key "announcements", "users", column: "author_id"
  add_foreign_key "assignment_resources", "assignments"
  add_foreign_key "assignment_step_answer_keys", "assignment_steps"
  add_foreign_key "assignment_steps", "assignments"
  add_foreign_key "assignments", "classrooms"
  add_foreign_key "assignments", "subject_topics"
  add_foreign_key "assignments", "subjects"
  add_foreign_key "assignments", "users", column: "teacher_id"
  add_foreign_key "attendance_records", "classrooms"
  add_foreign_key "attendance_records", "schools"
  add_foreign_key "attendance_records", "subjects"
  add_foreign_key "attendance_records", "users", column: "student_id"
  add_foreign_key "attendance_records", "users", column: "teacher_id"
  add_foreign_key "calendar_events", "assignments"
  add_foreign_key "calendar_events", "schools"
  add_foreign_key "classroom_users", "classrooms"
  add_foreign_key "classroom_users", "users"
  add_foreign_key "classrooms", "schools"
  add_foreign_key "comments", "users", column: "author_id"
  add_foreign_key "conversation_participants", "conversations"
  add_foreign_key "conversation_participants", "messages", column: "last_read_message_id"
  add_foreign_key "conversation_participants", "users"
  add_foreign_key "conversations", "messages", column: "last_message_id"
  add_foreign_key "conversations", "schools"
  add_foreign_key "conversations", "users", column: "created_by_id"
  add_foreign_key "daily_quiz_answers", "daily_quiz_questions"
  add_foreign_key "daily_quiz_answers", "schools"
  add_foreign_key "daily_quiz_answers", "users", column: "student_id"
  add_foreign_key "daily_quiz_questions", "schools"
  add_foreign_key "daily_quiz_questions", "users", column: "created_by_id"
  add_foreign_key "discussion_posts", "discussion_posts", column: "parent_post_id"
  add_foreign_key "discussion_posts", "discussion_threads"
  add_foreign_key "discussion_posts", "users", column: "author_id"
  add_foreign_key "discussion_spaces", "assignments"
  add_foreign_key "discussion_spaces", "classrooms"
  add_foreign_key "discussion_spaces", "schools"
  add_foreign_key "discussion_spaces", "subjects"
  add_foreign_key "discussion_spaces", "users", column: "created_by_id"
  add_foreign_key "discussion_threads", "discussion_spaces"
  add_foreign_key "discussion_threads", "users", column: "creator_id"
  add_foreign_key "event_participants", "calendar_events"
  add_foreign_key "event_participants", "users"
  add_foreign_key "grades", "submissions"
  add_foreign_key "grades", "users", column: "teacher_id"
  add_foreign_key "homeroom_assignments", "classrooms"
  add_foreign_key "homeroom_assignments", "schools"
  add_foreign_key "homeroom_assignments", "users", column: "teacher_id"
  add_foreign_key "learning_game_configs", "schools"
  add_foreign_key "message_attachments", "messages"
  add_foreign_key "message_deliveries", "messages"
  add_foreign_key "message_deliveries", "users"
  add_foreign_key "message_reactions", "messages"
  add_foreign_key "message_reactions", "users"
  add_foreign_key "message_reads", "messages"
  add_foreign_key "message_reads", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "messages", column: "reply_to_message_id"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "school_users", "schools"
  add_foreign_key "school_users", "users"
  add_foreign_key "student_badges", "schools"
  add_foreign_key "student_badges", "student_progress_profiles"
  add_foreign_key "student_badges", "users", column: "student_id"
  add_foreign_key "student_performance_snapshots", "classrooms"
  add_foreign_key "student_performance_snapshots", "schools"
  add_foreign_key "student_performance_snapshots", "users", column: "student_id"
  add_foreign_key "student_profiles", "schools"
  add_foreign_key "student_profiles", "users"
  add_foreign_key "student_progress_profiles", "schools"
  add_foreign_key "student_progress_profiles", "users", column: "student_id"
  add_foreign_key "student_reward_events", "schools"
  add_foreign_key "student_reward_events", "users", column: "student_id"
  add_foreign_key "subject_topics", "subjects"
  add_foreign_key "subjects", "schools"
  add_foreign_key "submission_step_answers", "assignment_steps"
  add_foreign_key "submission_step_answers", "submissions"
  add_foreign_key "submissions", "assignments"
  add_foreign_key "submissions", "users", column: "student_id"
  add_foreign_key "teacher_classrooms", "classrooms"
  add_foreign_key "teacher_classrooms", "users"
  add_foreign_key "teacher_profiles", "schools"
  add_foreign_key "teacher_profiles", "users"
  add_foreign_key "teacher_subjects", "subjects"
  add_foreign_key "teacher_subjects", "users", column: "teacher_id"
  add_foreign_key "user_presence_statuses", "users"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
