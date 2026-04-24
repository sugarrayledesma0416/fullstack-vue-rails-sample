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

ActiveRecord::Schema.define(version: 2025_06_07_120000) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "activities", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "points_possible"
    t.string "grading_method"
    t.integer "rank"
    t.boolean "gradeable"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "lesson_id"
    t.integer "strand_id"
    t.string "student_title"
    t.index ["lesson_id"], name: "index_activities_on_lesson_id"
    t.index ["strand_id"], name: "index_activities_on_strand_id"
  end

  create_table "assignments", id: :serial, force: :cascade do |t|
    t.integer "section_id"
    t.integer "activity_id"
    t.integer "category_id"
    t.integer "strand_id"
    t.integer "lesson_id"
    t.date "day_id"
    t.date "week_id"
    t.jsonb "details"
    t.integer "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "individually_assignable", default: false
    t.index ["category_id"], name: "index_assignments_on_category_id"
    t.index ["day_id"], name: "index_assignments_on_day_id"
    t.index ["lesson_id"], name: "index_assignments_on_lesson_id"
    t.index ["school_id"], name: "index_assignments_on_school_id"
    t.index ["section_id", "activity_id"], name: "index_assignments_on_section_id_and_activity_id", unique: true
    t.index ["strand_id"], name: "index_assignments_on_strand_id"
    t.index ["week_id"], name: "index_assignments_on_week_id"
  end

  create_table "attempt_durations", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "section_id", null: false
    t.integer "activity_id", null: false
    t.integer "school_id"
    t.integer "seconds_spent", default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["school_id"], name: "index_attempt_durations_on_school_id"
    t.index ["user_id", "section_id", "activity_id"], name: "index_on_user_section_activity", unique: true
  end

  create_table "categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "course_id"
    t.boolean "accept_late_work"
    t.float "weighting_percent"
    t.jsonb "details"
    t.integer "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["course_id"], name: "index_categories_on_course_id"
    t.index ["school_id"], name: "index_categories_on_school_id"
  end

  create_table "courses", id: :serial, force: :cascade do |t|
    t.string "name"
    t.date "start_date"
    t.date "end_date"
    t.integer "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "current_events_unit_id"
    t.integer "first_unit_id"
    t.integer "last_unit_id"
    t.index ["school_id"], name: "index_courses_on_school_id"
  end

  create_table "current_score_actions", force: :cascade do |t|
    t.integer "user_id"
    t.integer "section_id"
    t.integer "activity_id"
    t.bigint "score_action_id"
    t.jsonb "summation"
    t.integer "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["school_id"], name: "index_current_score_actions_on_school_id"
    t.index ["score_action_id"], name: "index_current_score_actions_on_score_action_id", unique: true
    t.index ["section_id", "activity_id", "user_id"], name: "current_score_actions_index", unique: true
  end

  create_table "drop_score_jobs", id: :serial, force: :cascade do |t|
    t.integer "section_id"
    t.integer "category_id"
    t.bigint "last_max_score_action_id"
    t.datetime "last_queued_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["section_id", "category_id"], name: "index_drop_score_jobs_on_section_id_and_category_id"
  end

  create_table "external_activities", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "points_possible"
    t.integer "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["school_id"], name: "index_external_activities_on_school_id"
  end

  create_table "external_assignments", id: :serial, force: :cascade do |t|
    t.integer "section_id"
    t.integer "external_activity_id"
    t.integer "lesson_id"
    t.integer "category_id"
    t.date "day_id"
    t.date "week_id"
    t.integer "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["category_id"], name: "index_external_assignments_on_category_id"
    t.index ["day_id"], name: "index_external_assignments_on_day_id"
    t.index ["lesson_id"], name: "index_external_assignments_on_lesson_id"
    t.index ["school_id"], name: "index_external_assignments_on_school_id"
    t.index ["section_id", "external_activity_id"], name: "idx_ext_assignment_section_id_ext_act_id", unique: true
    t.index ["week_id"], name: "index_external_assignments_on_week_id"
  end

  create_table "external_score_actions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "section_id"
    t.integer "external_activity_id"
    t.jsonb "summation"
    t.integer "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["external_activity_id", "section_id", "user_id"], name: "idx_esa_ea_id_section_id_user_id", unique: true
    t.index ["school_id"], name: "index_external_score_actions_on_school_id"
  end

  create_table "individual_assignments", force: :cascade do |t|
    t.integer "activity_id"
    t.integer "section_id"
    t.integer "user_id"
    t.date "day_id"
    t.date "week_id"
    t.index ["section_id", "activity_id", "user_id"], name: "individual_assignments_index", unique: true
    t.index ["section_id", "activity_id"], name: "index_individual_assignments_on_section_id_and_activity_id"
    t.index ["user_id"], name: "index_individual_assignments_on_user_id"
  end

  create_table "lessons", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "unit_rank"
    t.integer "rank"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "unit_id"
    t.integer "program_id"
  end

  create_table "lti_context_links", force: :cascade do |t|
    t.integer "lti_platform_id"
    t.string "deployment_id"
    t.string "context_id"
    t.string "context_label"
    t.string "context_title"
    t.string "line_items_url"
    t.integer "section_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "sync_enabled", default: false, null: false
    t.string "sync_level", default: "Cumulative"
    t.string "guid"
    t.string "platform_type"
    t.string "client_id"
    t.datetime "last_synced_at"
    t.string "last_synced_status"
    t.text "last_sync_error"
    t.text "category_ids"
    t.text "last_sync_warnings"
    t.boolean "skip_unsubmitted_work"
    t.index ["section_id"], name: "index_lti_context_links_on_section_id"
  end

  create_table "lti_platforms", force: :cascade do |t|
    t.string "name"
    t.string "issuer_id"
    t.string "keyset_url"
    t.string "oidc_auth_url"
    t.string "oauth2_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "client_id"
    t.string "guid"
    t.string "authorization_services_id"
    t.string "lms_type"
    t.boolean "disabled", default: false
    t.string "service_type"
  end

  create_table "lti_user_links", force: :cascade do |t|
    t.integer "lti_platform_id"
    t.string "platform_user_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "guid"
    t.index ["user_id", "lti_platform_id"], name: "index_lti_user_links_on_user_id_and_lti_platform_id"
  end

  create_table "migratable_sections", id: :serial, force: :cascade do |t|
    t.integer "section_id"
    t.date "course_end_date"
    t.boolean "migrated"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["section_id"], name: "index_migratable_sections_on_section_id"
  end

  create_table "reports", id: :serial, force: :cascade do |t|
    t.integer "owner_id", null: false
    t.integer "program_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name", null: false
    t.integer "first_lesson_id", null: false
    t.integer "last_lesson_id", null: false
    t.string "data_columns"
    t.integer "category_id", default: 0, null: false
    t.string "category_name", default: "All", null: false
    t.string "level", null: false
    t.boolean "from_specific_date", default: false, null: false
    t.date "start_date"
    t.boolean "to_specific_date", default: false, null: false
    t.date "end_date"
    t.index ["owner_id", "program_id"], name: "index_reports_on_owner_id_and_program_id"
  end

  create_table "score_actions", force: :cascade do |t|
    t.integer "user_id"
    t.integer "section_id"
    t.integer "activity_id"
    t.jsonb "action"
    t.jsonb "summation"
    t.integer "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["school_id"], name: "index_score_actions_on_school_id"
    t.index ["section_id", "activity_id", "user_id"], name: "index_score_actions_on_section_id_and_activity_id_and_user_id"
  end

  create_table "section_grade_offsets", id: :serial, force: :cascade do |t|
    t.integer "section_id"
    t.integer "user_id"
    t.float "offset"
    t.string "comment"
    t.integer "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["school_id"], name: "index_section_grade_offsets_on_school_id"
    t.index ["section_id", "user_id"], name: "index_section_grade_offsets_on_section_id_and_user_id", unique: true
  end

  create_table "section_users", id: :serial, force: :cascade do |t|
    t.integer "section_id"
    t.integer "user_id"
    t.integer "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["school_id"], name: "index_section_users_on_school_id"
    t.index ["section_id", "user_id"], name: "index_section_users_on_section_id_and_user_id", unique: true
  end

  create_table "sections", id: :serial, force: :cascade do |t|
    t.integer "course_id"
    t.interval "due_time"
    t.string "name"
    t.string "time_zone"
    t.integer "school_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "days_to_show_assignment_due_date"
    t.index ["course_id"], name: "index_sections_on_course_id"
    t.index ["school_id"], name: "index_sections_on_school_id"
  end

  create_table "strands", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "color"
    t.integer "rank"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "assessment", default: false
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "fake", default: false
    t.string "guid"
  end

end
