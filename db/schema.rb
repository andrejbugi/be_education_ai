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

ActiveRecord::Schema[8.0].define(version: 2026_03_12_190022) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.index ["assignment_id", "position"], name: "index_assignment_steps_on_assignment_id_and_position", unique: true
    t.index ["assignment_id"], name: "index_assignment_steps_on_assignment_id"
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
    t.index ["classroom_id", "subject_id", "due_at"], name: "index_assignments_on_classroom_id_and_subject_id_and_due_at"
    t.index ["classroom_id"], name: "index_assignments_on_classroom_id"
    t.index ["subject_id"], name: "index_assignments_on_subject_id"
    t.index ["teacher_id"], name: "index_assignments_on_teacher_id"
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
    t.index ["code"], name: "index_schools_on_code", unique: true
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

  add_foreign_key "activity_logs", "users"
  add_foreign_key "assignment_steps", "assignments"
  add_foreign_key "assignments", "classrooms"
  add_foreign_key "assignments", "subjects"
  add_foreign_key "assignments", "users", column: "teacher_id"
  add_foreign_key "calendar_events", "assignments"
  add_foreign_key "calendar_events", "schools"
  add_foreign_key "classroom_users", "classrooms"
  add_foreign_key "classroom_users", "users"
  add_foreign_key "classrooms", "schools"
  add_foreign_key "comments", "users", column: "author_id"
  add_foreign_key "event_participants", "calendar_events"
  add_foreign_key "event_participants", "users"
  add_foreign_key "grades", "submissions"
  add_foreign_key "grades", "users", column: "teacher_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "school_users", "schools"
  add_foreign_key "school_users", "users"
  add_foreign_key "student_profiles", "schools"
  add_foreign_key "student_profiles", "users"
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
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
end
