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

ActiveRecord::Schema.define(version: 2025_10_08_063801) do

  create_table "activities", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "title"
    t.integer "concept_id"
    t.string "page"
    t.string "icon"
    t.string "component_name"
    t.integer "toc_location"
    t.integer "lesson_id"
    t.integer "minutes_to_complete"
    t.integer "cms_activity_id"
    t.integer "cms_revision_id"
    t.integer "toc_location_rank"
    t.integer "concept_rank"
    t.integer "points_possible"
    t.string "activity_type"
    t.string "grading_method"
    t.string "thumbnail_path"
    t.string "singular_label", default: "activity"
    t.text "content_summary"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "submittable"
    t.integer "max_attempts"
    t.integer "license_group_id"
    t.integer "instructor_revision_id"
    t.integer "instructor_id"
    t.boolean "hide_from_my_content", default: false
    t.boolean "cdn", default: false
    t.boolean "randomizable", default: true
    t.string "assignment_group"
    t.boolean "draft"
    t.string "student_title"
    t.bigint "question_bank_revision_id"
    t.bigint "question_bank_topic_id"
    t.boolean "has_vhl_image"
    t.boolean "has_rubric"
    t.string "component_language", default: "en"
    t.index ["cms_activity_id"], name: "index_activities_on_cms_activity_id"
    t.index ["concept_id"], name: "index_activities_on_concept_id"
    t.index ["lesson_id"], name: "index_activities_on_lesson_id"
    t.index ["toc_location", "toc_location_rank"], name: "by_location_sort_by_rank"
  end

  create_table "activity_notes", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "activity_id"
    t.integer "program_id"
    t.string "note_type", default: "collapsed", null: false
    t.integer "focused_course_id"
    t.text "body_text"
    t.integer "cms_revision_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "note_item_id"
    t.text "title"
    t.integer "recording_id"
    t.integer "video_recording_id"
    t.index ["user_id", "activity_id"], name: "by_user_and_activity"
  end

  create_table "ai_chat_feedback_flags", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "comment"
    t.string "message_guid"
    t.integer "graded_by_id"
    t.integer "program_id", null: false
    t.integer "activity_id", null: false
    t.bigint "ai_virtual_chat_session_messages_id", null: false
    t.bigint "ai_suggestion_rating_categories_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["ai_suggestion_rating_categories_id"], name: "idx_feedback_flags_on_rating_category"
    t.index ["ai_virtual_chat_session_messages_id"], name: "idx_feedback_flags_on_chat_message"
    t.index ["program_id", "activity_id", "message_guid"], name: "ai_chat_feedback_flags_on_program_activity_message", unique: true
  end

  create_table "ai_chat_overall_feedbacks", charset: "utf8", collation: "utf8_general_ci", force: :cascade do |t|
    t.string "comment"
    t.integer "graded_by_id"
    t.integer "program_id", null: false
    t.integer "activity_id", null: false
    t.bigint "ai_virtual_chat_sessions_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["ai_virtual_chat_sessions_id"], name: "idx_overall_feedbacks_on_session"
  end

  create_table "ai_grading_suggestion_inputs", charset: "utf8", force: :cascade do |t|
    t.integer "program_id", null: false
    t.integer "activity_id", null: false
    t.bigint "attempt_id", null: false
    t.string "question_label", null: false
    t.text "student_response", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["activity_id", "question_label"], name: "index_ai_grading_suggestion_inputs_on_activity_question_label"
    t.index ["attempt_id", "question_label"], name: "index_ai_grading_suggestion_inputs_on_attempt_question_label"
    t.index ["program_id"], name: "index_ai_grading_suggestion_inputs_on_program_id"
  end

  create_table "ai_grading_suggestion_jobs", charset: "utf8mb3", collation: "utf8mb3_general_ci", force: :cascade do |t|
    t.bigint "attempt_id", null: false
    t.string "question_label", null: false
    t.string "status", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "error"
    t.index ["attempt_id", "question_label"], name: "index_on_attempt_and_question_label"
  end

  create_table "ai_grading_suggestion_prompts", charset: "utf8", force: :cascade do |t|
    t.text "template_body", null: false
    t.string "model", null: false
    t.float "temperature"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "active_for_instructor_grading", default: false
  end

  create_table "ai_grading_suggestion_ratings", charset: "utf8", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "grading_suggestion_id", null: false
    t.integer "rating_category_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "comment"
    t.index ["grading_suggestion_id"], name: "index_ai_grading_suggestion_ratings_on_grading_suggestion_id"
    t.index ["user_id", "grading_suggestion_id"], name: "ai_grading_suggestion_ratings_on_user_and_suggestion", unique: true
  end

  create_table "ai_grading_suggestions", charset: "utf8", force: :cascade do |t|
    t.integer "prompt_id"
    t.string "language_code", null: false
    t.integer "program_id", null: false
    t.integer "activity_id", null: false
    t.bigint "attempt_id", null: false
    t.string "question_label", null: false
    t.text "suggestion_text", null: false
    t.integer "reviewed_by_id"
    t.datetime "reviewed_at"
    t.string "reviewed_status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "grading_suggestion_input_id"
    t.integer "rating_category_id"
    t.string "rating_comment"
    t.integer "rated_by_id"
    t.timestamp "rated_at"
    t.boolean "edited", default: false
    t.bigint "ai_grading_suggestion_job_id"
    t.index ["activity_id"], name: "index_ai_grading_suggestions_on_activity_id"
    t.index ["ai_grading_suggestion_job_id"], name: "index_ai_grading_suggestions_on_ai_grading_suggestion_job_id"
    t.index ["attempt_id"], name: "index_ai_grading_suggestions_on_attempt_id"
    t.index ["grading_suggestion_input_id"], name: "index_ai_grading_suggestions_on_grading_suggestion_input_id"
  end

  create_table "ai_overall_comment_prompts", charset: "utf8", force: :cascade do |t|
    t.text "template_body", null: false
    t.string "model", null: false
    t.float "temperature"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "active_for_instructor_grading", default: false
  end

  create_table "ai_overall_comment_ratings", charset: "utf8", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "overall_comment_id", null: false
    t.integer "rating_category_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "comment"
    t.index ["overall_comment_id"], name: "index_ai_overall_comment_ratings_on_overall_comment_id"
    t.index ["user_id", "overall_comment_id"], name: "ai_overall_comment_ratings_on_user_and_overall_comment", unique: true
  end

  create_table "ai_overall_comments", charset: "utf8", force: :cascade do |t|
    t.integer "prompt_id"
    t.string "language_code", null: false
    t.integer "program_id", null: false
    t.integer "activity_id", null: false
    t.bigint "attempt_id", null: false
    t.string "question_label", null: false
    t.text "evaluation_text", null: false
    t.integer "reviewed_by_id"
    t.datetime "reviewed_at"
    t.string "reviewed_status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "grading_suggestion_input_id"
    t.integer "rating_category_id"
    t.string "rating_comment"
    t.integer "rated_by_id"
    t.timestamp "rated_at"
    t.boolean "edited", default: false
    t.index ["activity_id"], name: "index_ai_overall_comments_on_activity_id"
    t.index ["attempt_id"], name: "index_ai_overall_comments_on_attempt_id"
    t.index ["grading_suggestion_input_id"], name: "index_ai_overall_feedback_on_grading_suggestion_input_id"
  end

  create_table "ai_suggestion_rating_categories", charset: "utf8", force: :cascade do |t|
    t.boolean "internal_use", default: false, null: false
    t.boolean "boolean", default: false, null: false
    t.text "label"
    t.string "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "ai_suggestion_rating_details", charset: "utf8", force: :cascade do |t|
    t.integer "program_id", null: false
    t.integer "activity_id", null: false
    t.bigint "attempt_id", null: false
    t.integer "updated_by_id"
    t.string "question_label", null: false
    t.text "comment"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["attempt_id", "question_label"], name: "index_ai_suggestion_rating_details_on_attempt_and_question_label", unique: true
  end

  create_table "ai_virtual_chat_session_messages", charset: "utf8", force: :cascade do |t|
    t.integer "session_id"
    t.string "guid", null: false
    t.string "role"
    t.text "message_text"
    t.text "audio_file_path"
    t.text "ai_api_response"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["session_id", "guid"], name: "index_ai_virtual_chat_session_messages_on_session_id_and_guid", unique: true
  end

  create_table "ai_virtual_chat_sessions", charset: "utf8mb3", collation: "utf8mb3_general_ci", force: :cascade do |t|
    t.text "model_config"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "attempt_id"
    t.integer "user_id"
    t.integer "activity_id"
    t.text "completion_failure_reason"
    t.text "preview_system_prompt"
    t.index ["attempt_id"], name: "index_ai_virtual_chat_sessions_on_attempt_id"
    t.index ["user_id"], name: "index_ai_virtual_chat_sessions_on_user_id"
  end

  create_table "announcement_sections", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "announcement_id", null: false
    t.integer "section_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["section_id"], name: "index_announcement_sections_on_section_id"
  end

  create_table "announcements", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "author_id"
    t.boolean "is_archived", default: false, null: false
    t.string "title", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_link_title"
    t.string "external_link_url"
    t.string "file_name"
    t.date "show_on"
    t.boolean "class_cancelled", default: false
  end

  create_table "assessment_items", charset: "utf8", collation: "utf8_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=COMPACT", force: :cascade do |t|
    t.string "guid", null: false
    t.integer "assessment_id", null: false
    t.integer "points_possible"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["guid"], name: "index_assessment_items_on_guid"
    t.index ["assessment_id"], name: "index_assessment_items_on_assessment_id"
  end

  create_table "assessment_student_time_limits", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "section_id"
    t.integer "activity_id"
    t.integer "time_limit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["section_id", "activity_id", "user_id"], name: "by_section_activity_user_index", unique: true
  end

  create_table "assigned_assessment_details", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "assignment_id", null: false
    t.string "password"
    t.integer "time_limit", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "number_of_attempts", default: 1
    t.index ["assignment_id"], name: "index_assigned_assessment_details_on_assignment_id"
  end

  create_table "assignment_filters", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "course_id"
    t.integer "lesson_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "toc_entry_location"
    t.integer "previous_section_id"
    t.string "component"
    t.integer "category_id"
    t.string "week"
    t.string "activity_type"
    t.string "grading_method"
    t.date "day"
    t.string "content_type"
    t.index ["course_id", "user_id"], name: "by_course_and_user"
  end

  create_table "assignment_set_activities", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "assignment_set_rank"
    t.bigint "activity_id"
    t.bigint "assignment_set_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_assignment_set_activities_on_activity_id"
    t.index ["assignment_set_id"], name: "index_assignment_set_activities_on_assignment_set_id"
  end

  create_table "assignment_sets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.date "due_date"
    t.bigint "section_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["section_id", "due_date"], name: "index_assignment_sets_on_section_id_and_due_date"
    t.index ["section_id"], name: "index_assignment_sets_on_section_id"
  end

  create_table "assignments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.date "due_date"
    t.integer "study_schedule_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "rank", default: 0
    t.integer "category_id"
    t.boolean "current", default: false
    t.integer "assignable_id"
    t.string "assignable_type"
    t.string "show_assessment"
    t.datetime "show_at"
    t.string "grade_availability"
    t.datetime "grades_available_at"
    t.string "answer_availability"
    t.datetime "answers_available_at"
    t.time "custom_due_time"
    t.integer "section_id"
    t.integer "track_group_id"
    t.integer "assigned_assessment_detail_id"
    t.boolean "randomize_per_student", default: false, null: false
    t.boolean "individually_assignable", default: false
    t.index ["assignable_id"], name: "index_assignments_on_assignable_id"
    t.index ["category_id"], name: "index_assignments_on_category_id"
    t.index ["due_date", "rank"], name: "due_date_rank"
    t.index ["section_id", "assignable_type", "assignable_id"], name: "section_assignment_uniqueness", unique: true
    t.index ["section_id"], name: "assignment_section"
    t.index ["study_schedule_id", "assignable_id", "assignable_type"], name: "assignment_uniqueness", unique: true, length: { assignable_type: 20 }
    t.index ["study_schedule_id", "due_date"], name: "by_study_schedule_and_due_date"
    t.index ["study_schedule_id"], name: "index_assignments_on_study_schedule_id"
  end

  create_table "attempt_configs", charset: "utf8", force: :cascade do |t|
    t.integer "artifact_sharing_status", default: 0
    t.bigint "attempt_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attempt_id"], name: "index_attempt_configs_on_attempt_id"
  end

  create_table "attempts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "section_id"
    t.integer "activity_id"
    t.integer "status_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "offset_bytes"
    t.integer "record_length"
    t.integer "cms_revision_id"
    t.integer "save_offset_bytes", default: 0
    t.integer "save_record_length", default: 0
    t.integer "attempt_number", default: 0
    t.integer "time_spent", default: 0
    t.integer "scoring_ruleset_id"
    t.integer "cms_activity_id"
    t.datetime "start_time"
    t.bigint "submission_id"
    t.bigint "saved_submission_id"
    t.index ["activity_id"], name: "index_attempts_on_activity_id"
    t.index ["cms_activity_id"], name: "index_attempts_on_cms_activity_id"
    t.index ["cms_revision_id"], name: "index_attempts_on_cms_revision_id"
    t.index ["section_id"], name: "index_attempts_on_section_id"
    t.index ["user_id", "activity_id"], name: "by_user_and_activity"
    t.index ["user_id", "section_id", "activity_id", "status_code"], name: "attempt_uniqueness", unique: true
    t.index ["user_id"], name: "index_attempts_on_user_id"
  end

  create_table "audio_sample_agreements", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.boolean "allows_recording", default: false, null: false
    t.string "context", default: "project_george"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_audio_sample_agreements_on_user_id"
  end

  create_table "audio_sample_target_activities", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "activity_revision_id"
    t.integer "word_count", null: false
    t.integer "completions_desired", null: false
    t.integer "batch_number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "audio_sample_targets", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "dictionary_id"
    t.string "word", null: false
    t.string "audio_file", null: false
    t.integer "samples_desired", default: 150, null: false
    t.string "batch_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "audio_samples", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.string "word"
    t.string "s3_path", limit: 1024
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "audio_sample_target_id"
    t.boolean "self_report_correct"
    t.integer "item_index"
    t.integer "audio_sample_target_activity_id"
    t.index ["audio_sample_target_activity_id"], name: "index_audio_samples_on_audio_sample_target_activity_id"
    t.index ["audio_sample_target_id"], name: "index_audio_samples_on_audio_sample_target_id"
  end

  create_table "backup_sessions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bulk_resources_creation_trackers", charset: "utf8mb3", collation: "utf8mb3_general_ci", force: :cascade do |t|
    t.string "zip_file_name"
    t.string "csv_file_name"
    t.string "state"
    t.text "logs", size: :long, default: "{}", null: false, collation: "utf8mb4_bin"
    t.integer "program_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.check_constraint "json_valid(`logs`)", name: "logs"
  end

  create_table "cartridge_build_statuses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "cc_version"
    t.string "status"
    t.string "error_message"
    t.string "file_name"
    t.integer "creator_id"
    t.integer "program_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cartridge_consumers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.text "key", null: false
    t.text "secret", null: false
    t.integer "school_id"
    t.string "guid"
    t.bigint "sync_token", default: 0
    t.string "request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["guid"], name: "index_cartridge_consumers_on_guid"
    t.index ["school_id"], name: "index_cartridge_consumers_on_school_id"
  end

  create_table "cartridge_course_context_details", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "lms_context_id", null: false
    t.text "launch_presentation_return_url"
    t.string "lis_outcome_service_url"
    t.bigint "course_id", null: false
    t.integer "section_id", null: false
    t.bigint "school_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_archived", default: false
    t.integer "program_id"
    t.string "line_items_url"
    t.index ["lms_context_id", "school_id", "program_id"], name: "idx_cartridge_crs_context_details_on_lms_context_id_school_prog", unique: true
    t.index ["lms_context_id"], name: "index_cartridge_course_context_details_on_lms_context_id"
    t.index ["section_id"], name: "index_cartridge_course_context_details_on_section_id"
  end

  create_table "cartridge_line_item_destinations", charset: "utf8", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "section_id", null: false
    t.bigint "activity_id", null: false
    t.string "line_item_url", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id", "section_id", "activity_id"], name: "index_cartridge_line_item_destinations_on_user_section_activity", unique: true
  end

  create_table "cartridge_resource_links", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "resource_id", null: false
    t.string "resource_type", null: false
    t.string "resource_link_id", null: false
    t.integer "program_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id"], name: "index_cartridge_resource_links_on_program_id"
    t.index ["resource_link_id"], name: "index_cartridge_resource_links_on_resource_link_id", unique: true
    t.index ["resource_id", "resource_type"], name: "index_cartridge_resource_links_on_resource_id_and_resource_type", unique: true
  end

  create_table "cartridge_score_destinations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "section_id", null: false
    t.bigint "activity_id", null: false
    t.string "lis_result_sourcedid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "section_id", "activity_id"], name: "index_cartridge_score_destinations_on_user_section_activity", unique: true
  end

  create_table "cartridge_user_links", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "school_id"
    t.integer "user_id"
    t.boolean "contexts_owner", default: false, null: false
    t.string "external_user_id"
    t.string "guid"
    t.bigint "sync_token", default: 0
    t.string "request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
    t.index ["guid"], name: "index_cartridge_user_links_on_guid"
    t.index ["user_id"], name: "index_cartridge_user_links_on_user_id", unique: true
  end

  create_table "categories", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "course_id"
    t.integer "label_id"
    t.integer "rank", default: 0, null: false
    t.boolean "is_archived", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "weighting_percent"
    t.string "name"
    t.string "group_name"
    t.integer "current_scoring_ruleset_id"
    t.integer "max_attempts"
    t.boolean "enhanced_feedback_disabled", default: false
    t.boolean "accept_late_work", default: true
    t.string "late_work_penalty", default: "percent_per_day"
    t.integer "penalty_percent", default: 5
    t.boolean "credit_only", default: false
    t.integer "drop_low_scores", default: 0, null: false
    t.index ["course_id", "rank"], name: "by_course_sort_by_rank"
    t.index ["rank"], name: "index_categories_on_rank"
  end

  create_table "chat_click_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "source_tag"
    t.string "username"
    t.string "ip"
    t.string "os"
    t.string "browser"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "chat_errors", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "activity_id"
    t.string "error"
    t.string "flash_version"
    t.string "browser"
    t.string "browser_version"
    t.string "platform"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "partner_id"
    t.integer "message_id"
    t.string "resource_id"
  end

  create_table "composition_attachments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "file_name"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "draft", default: true
    t.integer "replaces_attachment_id"
  end

  create_table "concepts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "program_id"
    t.integer "lesson_id"
    t.integer "rank"
    t.string "name"
    t.string "breadcrumb_string"
    t.string "background_color"
    t.boolean "assessment", default: false
    t.string "singular_label", default: "activity"
    t.string "base_name", default: "", null: false
    t.integer "media_item_id"
    t.integer "lesson_combined_rank", default: 0, null: false
    t.index ["lesson_id"], name: "index_concepts_on_lesson_id"
    t.index ["program_id"], name: "index_concepts_on_program_id"
  end

  create_table "countries", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "code", null: false
    t.string "name"
    t.index ["code"], name: "index_countries_on_code"
  end

  create_table "course_library_activities", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "activity_id"
    t.integer "course_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "hidden", default: true
    t.index ["activity_id", "course_id"], name: "index_course_activities_on_activity_id_and_course_id"
    t.index ["course_id"], name: "by_course"
  end

  create_table "course_standard_sets", charset: "utf8", force: :cascade do |t|
    t.bigint "course_id"
    t.bigint "standard_set_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["course_id"], name: "index_course_standard_sets_on_course_id"
    t.index ["standard_set_id"], name: "index_course_standard_sets_on_standard_set_id"
  end

  create_table "courses", id: :integer, charset: "utf8", collation: "utf8_unicode_ci", options: "ENGINE=InnoDB ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.string "level"
    t.integer "program_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "school_id"
    t.date "start_date"
    t.date "end_date"
    t.boolean "is_archived", default: false
    t.integer "owner_id"
    t.boolean "is_demo", default: false
    t.integer "first_unit_id"
    t.integer "last_unit_id"
    t.string "components"
    t.string "video_subtitle_languages", default: "foreign"
    t.string "video_transcript_languages", default: "none", null: false
    t.boolean "allow_video_popup_translation", default: false, null: false
    t.boolean "draft", default: false
    t.text "course_package_ids"
    t.boolean "allows_review_requests", default: false
    t.boolean "allows_help_requests", default: false
    t.string "chat_level", default: "partner_chat"
    t.boolean "show_estimated_times", default: true, null: false
    t.string "guid"
    t.bigint "sync_token", default: 0
    t.string "request_id"
    t.boolean "allow_audio_transcripts", default: false, null: false
    t.boolean "is_template", default: false, null: false
    t.integer "source_template_id"
    t.string "creator_guid"
    t.boolean "hide_from_instructor_dashboard", default: false
    t.boolean "share_to_google_classroom", default: true
    t.boolean "allow_individual_assign", default: false
    t.boolean "enable_vocab_tutorial_translations", default: false
    t.text "course_config_json", default: ""
    t.boolean "share_to_portfolio", default: false
    t.text "portfolio_activity_types", size: :long, collation: "utf8mb4_bin"
    t.boolean "is_enterprise", default: false
    t.boolean "ai_virtual_chat_level", default: false
    t.index ["creator_guid"], name: "index_courses_on_creator_guid"
    t.index ["guid"], name: "index_courses_on_guid", unique: true
    t.index ["owner_id", "name", "start_date"], name: "by_owner_sort_by_name_and_start_date"
    t.index ["program_id"], name: "index_courses_on_program_id"
    t.index ["school_id"], name: "index_courses_on_school_id"
  end

  create_table "custom_rubrics", charset: "utf8mb3", collation: "utf8mb3_general_ci", force: :cascade do |t|
    t.bigint "activity_id"
    t.bigint "source_activity_id"
    t.integer "source_rubric_id"
    t.bigint "instructor_id"
    t.bigint "course_id"
    t.boolean "draft", default: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "stored_rubric"
    t.integer "rubric_revision"
    t.integer "activity_revision_id"
    t.integer "strand_id"
    t.index ["activity_id"], name: "index_custom_rubrics_on_activity_id"
    t.index ["source_activity_id"], name: "index_custom_rubrics_on_source_activity_id"
  end

  create_table "dashboard_announcements", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "title", null: false
    t.text "body", null: false
    t.boolean "supersite", null: false
    t.boolean "vol", null: false
    t.string "external_url", null: false
    t.string "link_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "default_vocab_tags", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.integer "default_vocab_word_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["default_vocab_word_id"], name: "by_default_vocab_word"
  end

  create_table "default_vocab_words", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "program_id"
    t.string "target_word", default: ""
    t.string "base_word", default: ""
    t.string "target_definition", default: ""
    t.string "language"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "lesson_id"
    t.integer "vocab_program_group_id"
    t.index ["program_id"], name: "by_program"
  end

  create_table "default_vocabulary_words", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "program_id", null: false
    t.integer "lesson_id", null: false
    t.string "composite_dictionary_id", null: false
    t.string "topic", null: false
    t.string "target", null: false
    t.string "translation", null: false
    t.string "definition"
    t.string "audio_paths", limit: 2048
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pinyin"
    t.index ["composite_dictionary_id"], name: "idx_default_vocabulary_words_composite_dictionary"
  end

  create_table "delayed_jobs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "priority", default: 0
    t.integer "attempts", default: 0
    t.text "handler"
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "queue"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "drop_lowest_score_jobs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "section_id", default: 0, null: false
    t.integer "category_id", default: 0, null: false
    t.integer "user_id", default: 0, null: false
    t.boolean "enqueued", default: false, null: false
    t.datetime "started_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_drop_lowest_score_jobs_on_category_id"
    t.index ["section_id", "category_id", "user_id"], name: "section_category_user"
  end

  create_table "ereader_items", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "guid", null: false
    t.string "title", null: false
    t.string "page_section", null: false
    t.string "descriptor"
    t.integer "page_number", null: false
    t.bigint "concept_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["concept_id"], name: "index_ereader_items_on_concept_id"
  end

  create_table "enrollments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "section_id"
    t.integer "added_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "dropped_by_id"
    t.datetime "dropped_at"
    t.boolean "inactive", default: false
    t.string "state", default: "enrolled"
    t.boolean "blocked", default: false, null: false
    t.integer "section_transferred_to"
    t.integer "transferred_from"
    t.boolean "sufficient_access", default: true
    t.string "guid"
    t.bigint "sync_token", default: 0
    t.string "request_id"
    t.index ["guid"], name: "index_enrollments_on_guid", unique: true
    t.index ["section_id"], name: "index_enrollments_on_section_id"
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "events", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.date "date"
    t.integer "instructor_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "class_cancelled", default: false
    t.boolean "archived", default: false, null: false
    t.index ["date"], name: "index_section_events_on_date"
  end

  create_table "external_activities", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "title"
    t.integer "toc_location"
    t.integer "lesson_id"
    t.integer "points_possible"
    t.integer "program_id"
    t.integer "course_id"
    t.integer "section_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "feedback_item_ai_comments", charset: "utf8", force: :cascade do |t|
    t.bigint "feedback_item_id"
    t.boolean "ai_generated_comment", default: false, null: false
    t.boolean "ai_generated_inline_corrections", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["feedback_item_id"], name: "index_feedback_item_ai_comments_on_feedback_item_id"
  end

  create_table "feedback_items", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "attempt_id"
    t.string "question_label"
    t.decimal "points_earned", precision: 8, scale: 2
    t.text "inline_corrections"
    t.text "comment"
    t.integer "user_id"
    t.integer "section_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "recording_id"
    t.integer "attachment_id"
    t.index ["attachment_id"], name: "index_feedback_items_on_attachment_id"
    t.index ["attempt_id"], name: "index_feedback_items_on_attempt_id"
    t.index ["question_label"], name: "index_feedback_items_on_question_label"
    t.index ["section_id"], name: "index_feedback_items_on_section_id"
    t.index ["user_id"], name: "index_feedback_items_on_user_id"
  end

  create_table "file_types", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "extension_name", null: false
    t.string "extension_description", null: false
    t.integer "is_archived", default: 0
    t.integer "is_allowed", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "forum_posts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "forum_id", null: false
    t.integer "user_id", null: false
    t.integer "parent_id"
    t.boolean "original_post", default: false, null: false
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "audio_path"
    t.datetime "edited_at"
    t.boolean "deleted", default: false, null: false
    t.index ["forum_id"], name: "by_forum"
  end

  create_table "forums", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "section_id", null: false
    t.integer "instructor_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["section_id"], name: "by_section"
  end

  create_table "general_logs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "log_type"
    t.string "data_format"
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "data_id"
    t.index ["created_at"], name: "index_general_logs_on_created_at"
    t.index ["data_id", "log_type"], name: "data_id_log_type_index"
  end

  create_table "grade_offsets", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "last_offset"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "section_id", null: false
    t.string "comment"
    t.index ["section_id"], name: "index_grade_offsets_on_section_id"
    t.index ["user_id"], name: "index_grade_offsets_on_user_id"
  end

  create_table "gradebook_v2_schools", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "school_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "idx_gradebook_v2_schools_school"
  end

  create_table "grades", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "section_id", null: false
    t.string "coordinates_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "category_id"
    t.decimal "points_earned_current", precision: 8, scale: 2, default: "0.0", null: false
    t.integer "points_possible_current", default: 0, null: false
    t.integer "activity_count_current", default: 0, null: false
    t.integer "completed_count_current", default: 0
    t.integer "time_spent_current", default: 0
    t.integer "attempt_count_current", default: 0
    t.decimal "points_earned_credit", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "points_pending", precision: 8, scale: 2, default: "0.0", null: false
    t.index ["category_id"], name: "index_grades_on_category_id"
    t.index ["coordinates_key", "category_id"], name: "by_coord_key_and_category", length: { coordinates_key: 12 }
    t.index ["section_id"], name: "index_grades_on_section_id"
    t.index ["user_id"], name: "index_grades_on_user_id"
  end

  create_table "grading_sets", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "program_id"
    t.integer "user_id"
    t.integer "activity_id"
    t.text "student_id_list"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "show_comments", default: false
    t.boolean "show_student_names", default: true
    t.index ["program_id", "user_id", "activity_id"], name: "index_grading_sets_on_program_id_and_user_id_and_activity_id", unique: true
  end

  create_table "group_chat_assignment_configs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.bigint "assignment_id", null: false
    t.integer "group_minimum", null: false
    t.integer "group_maximum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "index_group_chat_assignment_configs_on_assignment_id"
  end

  create_table "group_chat_recordings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "participants", limit: 4294967295, null: false, collation: "utf8mb4_bin"
    t.string "recording_path", null: false
    t.bigint "activity_id", null: false
    t.string "token", null: false
    t.text "practicing_users", limit: 4294967295, null: false, collation: "utf8mb4_bin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "idx_group_chat_recordings_activity_id"
  end

  create_table "group_sets", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "help_entries", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "page"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "published"
    t.integer "created_by_id"
    t.index ["page"], name: "index_help_entries_on_page", length: 32
  end

  create_table "help_requests", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "program_id"
    t.integer "activity_id"
    t.integer "section_id"
    t.integer "cms_activity_id"
    t.integer "cms_revision_id"
    t.string "activity_state"
    t.string "http_referer"
    t.string "ip_address"
    t.string "user_agent_string"
    t.string "browser_name"
    t.string "browser_version"
    t.string "operating_system"
    t.string "flash_version"
    t.string "request_params"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "student_comment"
    t.string "helpable_item_type"
    t.string "helpable_item_id"
    t.string "request_type", null: false
    t.string "status", default: "submitted", null: false
    t.text "instructor_comment"
    t.integer "processed_by"
    t.datetime "processed_at"
    t.integer "severity_level", default: 2
    t.boolean "read_by_student", default: false, null: false
    t.index ["section_id", "request_type"], name: "index_help_requests_on_section_id_and_request_type", length: { request_type: 20 }
    t.index ["user_id", "activity_id"], name: "by_user_and_activity"
  end

  create_table "igc_copy_jobs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "instructor_id"
    t.integer "src_program_id"
    t.integer "dest_program_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "to_be_copied_ids"
    t.text "copied_ids"
  end

  create_table "individual_assignments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "activity_id"
    t.integer "section_id"
    t.integer "user_id"
    t.date "due_date"
    t.index ["section_id", "activity_id"], name: "index_individual_assignments_on_section_id_and_activity_id"
    t.index ["user_id"], name: "index_individual_assignments_on_user_id"
  end

  create_table "institution_admin_hidden_courses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "program_id"
    t.integer "course_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "program_id", "course_id"], name: "idx_hidden_courses__user_id__program_id__course_id", unique: true
  end

  create_table "instructor_activity_revisions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "activity_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "content_json", limit: 16777215
  end

  create_table "instructor_media_items", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "instructor_id"
    t.string "media_type"
    t.string "extname"
    t.integer "size"
    t.integer "width"
    t.integer "height"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "transcript"
  end

  create_table "instructor_resource_settings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "resource_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "student_visibility"
    t.index ["resource_id"], name: "index_instructor_resource_settings_on_resource_id"
    t.index ["user_id", "resource_id"], name: "by_user_and_resource"
  end

  create_table "job_status", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "last_run_at"
    t.datetime "last_success_at"
  end

  create_table "lessons", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.integer "rank"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "toc_entries_xml"
    t.string "label"
    t.integer "unit_id"
    t.string "use_type", default: "Lesson"
    t.index ["unit_id", "rank"], name: "by_unit_sort_by_rank"
  end

  create_table "license_package_passcodes", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "license_package_id"
    t.integer "passcode_id"
    t.integer "passcode_type"
    t.date "printed_on"
  end

  create_table "lti_context_links", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "lti_platform_id"
    t.string "deployment_id"
    t.string "context_id", collation: "utf8_bin"
    t.string "context_label"
    t.string "context_title"
    t.string "line_items_url"
    t.integer "section_id"
    t.string "guid"
    t.bigint "sync_token", default: 0
    t.string "request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "platform_type"
    t.string "client_id"
    t.string "memberships_service_url"
    t.index ["guid"], name: "index_lti_context_links_on_guid"
    t.index ["lti_platform_id", "context_id"], name: "index_lti_context_links_on_lti_platform_id_and_context_id"
  end

  create_table "lti_launches", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "jwt"
    t.text "decoded_jwt"
    t.integer "lti_tool_id"
    t.text "state"
    t.string "guid"
    t.bigint "sync_token", default: 0
    t.string "request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "lti_platform_id"
    t.text "deep_linking_settings"
    t.string "deployment_id"
    t.string "lms_user_id"
    t.index ["guid"], name: "index_lti_launches_on_guid"
  end

  create_table "lti_platforms", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "issuer_id"
    t.string "keyset_url"
    t.string "oidc_auth_url"
    t.string "oauth2_url"
    t.string "guid"
    t.bigint "sync_token", default: 0
    t.string "request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "client_id"
    t.string "authorization_services_id"
    t.string "lms_type"
    t.boolean "rostering", default: false
    t.integer "school_id"
    t.string "rostering_transition_from"
    t.boolean "disabled", default: false
    t.boolean "cartridge", default: false
    t.string "service_type"
    t.index ["guid"], name: "index_lti_platforms_on_guid"
  end

  create_table "lti_user_links", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "lti_platform_id"
    t.string "platform_user_id", collation: "utf8_bin"
    t.integer "user_id"
    t.string "guid"
    t.bigint "sync_token", default: 0
    t.string "request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "platform_user_email"
    t.index ["guid"], name: "index_lti_user_links_on_guid"
    t.index ["lti_platform_id", "platform_user_id", "user_id"], name: "idx_lti_user_links_platform_platform_user_user_id"
    t.index ["lti_platform_id", "platform_user_id"], name: "index_lti_user_links_on_lti_platform_id_and_platform_user_id"
    t.index ["user_id"], name: "index_lti_user_links_on_user_id"
  end

  create_table "maintenance_messages", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.text "message"
    t.datetime "start"
    t.datetime "end"
    t.boolean "published", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "media_items", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "filename"
    t.string "media_type"
    t.integer "size"
    t.integer "width"
    t.integer "height"
    t.text "transcript"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "asset_path"
    t.boolean "cdn", default: false, null: false
    t.string "alt_tag"
    t.text "long_description"
    t.integer "revision_id"
  end

  create_table "media_links", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "activity_id"
    t.integer "media_item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "instructor_uploaded"
    t.integer "transcript_mode", default: 0
  end

  create_table "notifications", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "section_id"
    t.string "type"
    t.boolean "dismissed", default: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "dismissed_at"
    t.integer "activity_id"
    t.integer "announcement_id"
    t.index ["activity_id"], name: "index_notifications_on_activity_id"
    t.index ["announcement_id"], name: "index_notifications_on_announcement_id"
    t.index ["dismissed_at"], name: "index_notifications_on_dismissed_at"
    t.index ["section_id", "activity_id"], name: "by_section_and_activity"
    t.index ["user_id", "section_id", "created_at"], name: "by_user_section_and_created_at"
  end

  create_table "one_roster_linked_sections", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "section_id", null: false
    t.string "class_external_id", null: false
    t.string "course_external_id", null: false
    t.string "academic_session"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "guid"
    t.bigint "sync_token", default: 0
    t.string "request_id"
    t.integer "school_id"
    t.boolean "is_archived", default: false
    t.index ["class_external_id", "course_external_id", "school_id", "section_id"], name: "idx_one_roster_linked_sections_on_class_and_course_and_school", unique: true
    t.index ["guid"], name: "index_one_roster_linked_sections_on_guid"
    t.index ["school_id"], name: "index_one_roster_linked_sections_on_school_id"
    t.index ["section_id"], name: "index_one_roster_linked_sections_on_section_id"
  end

  create_table "one_roster_linked_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "school_id", null: false
    t.string "external_username", null: false
    t.string "sourced_id", null: false
    t.string "email"
    t.string "guid"
    t.bigint "sync_token", default: 0
    t.string "request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["guid"], name: "index_one_roster_linked_users_on_guid"
    t.index ["school_id", "external_username"], name: "idx_one_roster_linked_users_school_username", unique: true
    t.index ["school_id"], name: "index_one_roster_linked_users_on_school_id"
    t.index ["user_id"], name: "index_one_roster_linked_users_on_user_id"
  end

  create_table "partner_chat_recordings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", default: 0, null: false
    t.integer "partner_id", default: 0, null: false
    t.string "recording_path", null: false
    t.integer "activity_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "token"
    t.boolean "partner_practice", default: false
  end

  create_table "password_attempts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "attempt_id"
    t.string "password"
    t.boolean "correct"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attempt_id"], name: "index_password_attempts_on_attempt_id"
  end

  create_table "processed_attempts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "attempt_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "program_configs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "program_id", null: false
    t.text "datastore_json"
    t.integer "creator_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "guid"
    t.bigint "sync_token", default: 0
    t.string "request_id"
    t.index ["program_id"], name: "index_program_configs_on_program_id"
  end

  create_table "program_editions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "program_id", null: false
    t.integer "next_edition_program_id"
    t.integer "previous_edition_program_id"
    t.string "guid"
    t.bigint "sync_token", default: 0
    t.string "request_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["guid"], name: "index_program_editions_on_guid"
    t.index ["program_id"], name: "index_program_editions_on_program_id"
  end

  create_table "program_media_items", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "program_id"
    t.integer "media_item_id"
    t.string "media_type"
    t.index ["media_item_id"], name: "index_program_media_items_on_media_item_id"
    t.index ["program_id"], name: "index_program_media_items_on_program_id"
  end

  create_table "program_to_program_mappings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "dest_program_id"
    t.integer "src_strand_id"
    t.integer "dest_strand_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "programs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "title"
    t.string "image_filename"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "language_code", limit: 2
    t.string "prefix_abbreviation"
    t.integer "maestro_version", default: 3
    t.string "vhlcentral_subdomain"
    t.integer "media_item_id"
    t.string "unit_label"
    t.string "lesson_label"
    t.boolean "vista_online_learning", default: false, null: false
    t.integer "vocab_program_group_id"
    t.string "family"
    t.boolean "is_archived", default: false
    t.boolean "tour_guide", default: false
    t.string "cover_path_small"
    t.string "cover_path_medium"
    t.string "cover_path_demo"
    t.string "title_part_main"
    t.string "title_part_main_language_code", limit: 2
    t.string "title_part_sub"
    t.string "title_part_sub_language_code", limit: 2
    t.string "title_part_edition"
    t.index ["vhlcentral_subdomain"], name: "index_programs_on_vhlcentral_subdomain"
    t.index ["vocab_program_group_id"], name: "by_vocab_program_group"
  end

  create_table "question_bank_revision_logs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "question_bank_revision_id"
    t.integer "user_id"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_bank_revision_id"], name: "index_question_bank_revision_logs_on_question_bank_revision_id"
  end

  create_table "question_bank_revisions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "activity_id"
    t.text "content_json"
    t.integer "changed_by_id"
    t.string "upload_filename"
    t.binary "uploaded_csv"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status"
    t.index ["activity_id"], name: "index_question_bank_revisions_on_activity_id"
  end

  create_table "question_bank_topics", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "language"
    t.string "level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "question_bank_topics_concepts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "question_bank_topic_id"
    t.bigint "concept_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["concept_id"], name: "index_question_bank_topics_concepts_on_concept_id"
    t.index ["question_bank_topic_id"], name: "index_question_bank_topics_concepts_on_question_bank_topic_id"
  end

  create_table "recordings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "recording_path"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "uuid"
    t.index ["recording_path"], name: "index_recordings_on_recording_path"
    t.index ["uuid"], name: "index_recordings_on_uuid"
  end

  create_table "reports", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "program_id"
    t.string "name"
    t.boolean "is_archived", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "configuration_xml"
    t.boolean "draft", default: true
    t.boolean "standard", default: false
    t.boolean "instructor_shared", default: false
  end

  create_table "resource_components", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "program_id"
    t.string "name"
    t.integer "rank", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id"], name: "by_program"
  end

  create_table "resources", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "title"
    t.string "file_name"
    t.integer "start_unit_id"
    t.integer "lesson_id"
    t.string "file_type", null: false
    t.string "source", null: false
    t.integer "program_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.integer "resource_component_id"
    t.boolean "vhl_student_resource", default: false
    t.boolean "protected", default: false
    t.boolean "uploaded", default: false
    t.integer "owner_id"
    t.integer "end_unit_id"
    t.string "subcomponent_name"
    t.boolean "is_archived", default: false
    t.datetime "uploaded_at"
    t.index ["program_id"], name: "index_resources_on_program_id"
    t.index ["resource_component_id"], name: "by_resource_component"
  end

  create_table "roles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name", limit: 40
    t.string "authorizable_type", limit: 40
    t.integer "authorizable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", length: 20
  end

  create_table "roles_users", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_roles_users_on_role_id"
    t.index ["user_id"], name: "index_roles_users_on_user_id"
  end

  create_table "rubric_criteria_scores", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "attempt_id"
    t.text "criteria_score_json"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attempt_id"], name: "idx_rubric_criteria_score_attempt_id"
  end

  create_table "scheduled_jobs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "worker_class", null: false
    t.text "args", limit: 16777215
    t.boolean "started", default: false, null: false
    t.string "jid", limit: 24
    t.integer "enqueued_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "scheduled_for"
    t.index ["jid"], name: "index_scheduled_jobs_on_jid"
  end

  create_table "school_configs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "school_id"
    t.boolean "chat_support_disabled", default: false, null: false
    t.string "guid"
    t.bigint "sync_token", default: 0
    t.string "request_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "instructor_timeout"
    t.integer "student_timeout"
    t.boolean "timeout_enabled", default: false, null: false
    t.string "web_token"
    t.string "institute_short_name"
    t.boolean "school_content_sharing", default: true, null: false
    t.text "program_content_sharing_json", size: :long, default: "{}", null: false
    t.index ["guid"], name: "index_school_configs_on_guid"
    t.index ["school_id"], name: "index_school_configs_on_school_id", unique: true
  end

  create_table "school_program_admin_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "school_id"
    t.integer "program_id"
    t.integer "user_id"
    t.string "guid"
    t.bigint "sync_token", default: 0
    t.string "request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "account_type", default: "InstitutionAdmin"
    t.index ["program_id", "user_id"], name: "program_id_user_id_index"
    t.index ["program_id"], name: "program_id_index"
    t.index ["school_id", "program_id", "user_id"], name: "school_id_program_id_user_id_index", unique: true
  end

  create_table "school_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "school_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "removed_at"
    t.string "guid"
    t.bigint "sync_token", default: 0
    t.string "request_id"
    t.index ["guid"], name: "index_school_users_on_guid", unique: true
    t.index ["school_id"], name: "index_school_users_on_school_id"
    t.index ["user_id", "school_id"], name: "index_school_users_on_user_id_and_school_id"
  end

  create_table "schools", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "school_type"
    t.integer "school_type_category"
    t.string "city"
    t.string "state"
    t.string "country_code"
    t.string "alternate_names"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "time_zone"
    t.boolean "is_archived", default: false
    t.string "zip_code", limit: 12
    t.bigint "common_words_bitmap"
    t.string "saleslogix_id"
    t.string "salesforce_id"
    t.integer "sales_rep_id"
    t.integer "district_id"
    t.string "district_salesforce_id"
    t.string "clever_id"
    t.string "guid"
    t.bigint "sync_token", default: 0
    t.string "request_id"
    t.string "district_clever_id"
    t.string "clever_integration_type"
    t.boolean "immediate_access", default: false, null: false
    t.date "immediate_access_start_date"
    t.integer "parent_institution_id"
    t.string "one_roster_integration_type"
    t.boolean "share_to_google_classroom", default: false
    t.datetime "share_to_google_classroom_last_updated_at", default: -> { "current_timestamp()" }
    t.index ["country_code"], name: "index_schools_on_country_code"
    t.index ["guid"], name: "index_schools_on_guid", unique: true
    t.index ["name"], name: "index_schools_on_name"
    t.index ["parent_institution_id"], name: "index_schools_on_parent_institution_id"
    t.index ["salesforce_id"], name: "index_schools_on_salesforce_id"
    t.index ["saleslogix_id"], name: "index_schools_on_saleslogix_id"
  end

  create_table "score_adjustments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "section_id"
    t.integer "student_id"
    t.integer "score_id"
    t.string "action"
    t.string "old_value"
    t.string "new_value"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["score_id"], name: "index_score_adjustments_on_score_id"
  end

  create_table "scores", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "section_id"
    t.integer "points_possible", default: 0, null: false
    t.decimal "points_earned", precision: 8, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "pending", default: false, null: false
    t.boolean "current", default: false, null: false
    t.boolean "late", default: false, null: false
    t.datetime "submitted_at"
    t.boolean "assigned", default: false, null: false
    t.integer "penalty_percent", default: 0, null: false
    t.boolean "adjusted", default: false, null: false
    t.integer "scorable_id"
    t.string "scorable_type"
    t.boolean "gradable", default: true, null: false
    t.integer "time_spent", default: 0
    t.string "grading_status", default: "auto"
    t.integer "submission_length"
    t.integer "attempt_count", default: 0
    t.decimal "points_earned_credit", precision: 8, scale: 2, default: "0.0", null: false
    t.integer "points_pending", default: 0
    t.datetime "originally_due_at"
    t.boolean "dropped", default: false, null: false
    t.index ["assigned"], name: "index_scores_on_assigned"
    t.index ["current"], name: "index_scores_on_current"
    t.index ["dropped"], name: "index_scores_on_dropped"
    t.index ["grading_status"], name: "index_scores_on_grading_status"
    t.index ["pending"], name: "index_scores_on_pending"
    t.index ["scorable_id", "scorable_type"], name: "scorable"
    t.index ["section_id", "user_id", "scorable_id", "scorable_type"], name: "score_uniqueness", unique: true
    t.index ["user_id", "scorable_id", "scorable_type"], name: "by_user_and_scorable", length: { scorable_type: 16 }
    t.index ["user_id", "section_id", "submitted_at"], name: "by_user_section_and_submitted_at"
  end

  create_table "scoring_rulesets", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "ignore_capitalization"
    t.boolean "ignore_accents"
    t.boolean "ignore_punctuation"
    t.index ["category_id"], name: "index_scoring_rulesets_on_category_id"
  end

  create_table "section_instructors", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "section_id"
    t.integer "user_id"
    t.boolean "is_archived", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
    t.string "guid"
    t.bigint "sync_token", default: 0
    t.string "request_id"
    t.boolean "show", default: true
    t.boolean "hide_from_instructor_dashboard", default: false
    t.boolean "allowed_to_edit_content", default: true
    t.index ["guid"], name: "index_section_instructors_on_guid", unique: true
    t.index ["section_id", "user_id"], name: "by_section_and_user"
    t.index ["user_id"], name: "index_section_instructors_on_user_id"
  end

  create_table "sections", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "name"
    t.integer "course_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "schedule"
    t.string "setting"
    t.integer "instructor_id"
    t.string "location"
    t.boolean "is_archived", default: false
    t.string "instructor_team_ids"
    t.boolean "pronto_enabled", default: false, null: false
    t.datetime "pronto_enabled_at"
    t.date "current_upto"
    t.time "due_time"
    t.string "additional_info"
    t.string "class_days", default: ""
    t.string "time_zone"
    t.boolean "hide_owner_name", default: false
    t.boolean "open_to_students", default: true
    t.string "guid"
    t.bigint "sync_token", default: 0
    t.string "request_id"
    t.integer "days_to_show_assignment_due_date"
    t.integer "source_template_id"
    t.boolean "shared", default: true
    t.boolean "is_enterprise", default: false
    t.boolean "audio_transcript"
    t.string "video_transcript_languages"
    t.string "video_subtitle_languages"
    t.string "input_mode", default: "speech"
    t.index ["course_id"], name: "index_sections_on_course_id"
    t.index ["guid"], name: "index_sections_on_guid", unique: true
  end

  create_table "server_error_reports", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.string "error_id"
    t.string "http_referer"
    t.string "ip_address"
    t.string "user_agent_string"
    t.string "browser_name"
    t.string "browser_version"
    t.string "operating_system"
    t.text "user_comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "session_id", null: false
    t.integer "user_id"
    t.string "ip_address"
    t.string "user_agent"
    t.string "service_ticket"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_activity_time_epoch"
    t.index ["service_ticket"], name: "index_sessions_on_service_ticket"
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "settings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.string "name"
    t.string "value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "index_settings_on_user_id"
  end

  create_table "shared_library_activities", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "activity_id"
    t.integer "school_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_shared", default: false
    t.integer "source_activity_id"
    t.integer "institution_admin_approver_id"
    t.boolean "allow_copy", default: false
    t.index ["activity_id", "school_id"], name: "idx_shared_library_activities__activity_id__school_id"
    t.index ["school_id"], name: "index_shared_library_activities_on_school_id"
  end

  create_table "site_licenses", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "school_id"
    t.integer "admin_id"
    t.string "slx_contact_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sales_rep_id"
    t.boolean "is_deactivated", default: false
    t.index ["admin_id"], name: "index_site_licenses_on_admin_id"
    t.index ["slx_contact_id"], name: "index_site_licenses_on_slx_contact_id"
  end

  create_table "site_licenses_packages", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "site_license_id"
    t.integer "package_id"
    t.date "start_date"
    t.integer "seats"
    t.integer "years"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "solo_video_recordings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "activity_id"
    t.string "recording_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "standard_alignments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "standard_asset_id", null: false
    t.string "vendor_asset_guid", null: false
    t.string "vendor_standard_guid", null: false
    t.string "alignment_status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["standard_asset_id"], name: "index_standard_alignments_on_standard_asset_id"
  end

  create_table "standard_assets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "vendor_guid", null: false
    t.integer "reference_id", null: false
    t.string "reference_type", null: false
    t.boolean "m3_publish_status"
    t.datetime "date_alignments_modified_utc"
    t.text "additional_attrs", size: :long, collation: "utf8mb4_bin"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["vendor_guid"], name: "index_standard_assets_on_vendor_guid", unique: true
  end

  create_table "standard_sets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "vendor_guid", null: false
    t.string "issuer", null: false
    t.string "name", null: false
    t.integer "adopt_year"
    t.string "state"
    t.string "acronym"
    t.text "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "display_name", default: ""
    t.index ["vendor_guid"], name: "index_standard_sets_on_vendor_guid"
  end

  create_table "standards", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "vendor_guid", null: false
    t.string "vendor_standard_set_guid", null: false
    t.string "name"
    t.text "description", null: false
    t.string "label"
    t.string "number"
    t.text "additional_info", size: :long, collation: "utf8mb4_bin"
    t.boolean "searchable", default: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["vendor_guid"], name: "index_standards_on_vendor_guid", unique: true
    t.index ["vendor_standard_set_guid"], name: "index_standards_on_vendor_standard_set_guid"
    t.check_constraint "json_valid(`additional_info`)", name: "additional_info"
  end

  create_table "standards_mapping_upload_statuses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "index_name", null: false
    t.string "upload_type", null: false
    t.boolean "successful", null: false
    t.text "upload_errors"
    t.datetime "uploaded_at_date", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["index_name", "successful"], name: "idx_stds_mapping_upload_statuses_on_index_name_and_successful"
  end

  create_table "standards_results", charset: "utf8", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "section_id", null: false
    t.integer "cms_activity_id", null: false
    t.text "results_data", size: :long, collation: "utf8mb4_bin"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["section_id", "cms_activity_id", "user_id"], name: "activity_section_user", unique: true
  end

  create_table "student_section_configs", charset: "utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "section_id"
    t.string "video_subtitle_languages"
    t.string "video_transcript_languages"
    t.boolean "audio_transcript"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "input_mode", default: "speech"
    t.index ["section_id"], name: "index_student_section_configs_on_section_id"
    t.index ["user_id"], name: "index_student_section_configs_on_user_id"
  end

  create_table "student_spotcheck_counts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "section_id", null: false
    t.integer "count"
  end

  create_table "study_plan_concept_recommendations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "study_plan_concept_id", null: false
    t.integer "cms_activity_id"
    t.string "recommendation_type"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "study_plan_concepts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "activity_id", null: false
    t.integer "program_id", null: false
    t.integer "cms_revision_id", null: false
    t.string "reference_id"
    t.string "title"
    t.integer "threshold"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "track_groups", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.integer "program_id"
    t.integer "lesson_id"
    t.integer "concept_id"
    t.string "how_to_use"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "objective"
    t.integer "group_set_id"
  end

  create_table "units", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.integer "rank"
    t.integer "program_id"
    t.string "label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "toc_location"
    t.integer "media_item_id"
    t.string "use_type", default: "Unit"
    t.boolean "released", default: false, null: false
    t.string "english_title"
    t.string "chinese_title"
    t.string "pinyin_title"
    t.string "resources_form_title"
    t.index ["program_id", "rank"], name: "by_program_sort_by_rank"
  end

  create_table "user_defined_words", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "program_id", null: false
    t.integer "lesson_id", null: false
    t.integer "user_id", null: false
    t.string "target", null: false
    t.string "translation", null: false
    t.string "definition", limit: 512
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pinyin"
  end

  create_table "user_readings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "study_plan_concept_recommendation_id", null: false
    t.boolean "viewed"
    t.integer "concept_score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "study_plan_concept_recommendation_id"], name: "index_user_readings_by_user_and_recommendation"
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "username", null: false, collation: "utf8_bin"
    t.string "email", null: false, collation: "utf8_bin"
    t.string "crypted_password"
    t.string "password_salt"
    t.string "persistence_token"
    t.string "single_access_token"
    t.string "perishable_token"
    t.integer "login_count", default: 0
    t.integer "failed_login_count", default: 0
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string "current_login_ip"
    t.string "last_login_ip"
    t.integer "year_of_birth"
    t.string "secret_question"
    t.string "secret_answer"
    t.datetime "first_dashboard_viewed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "student_id"
    t.string "time_zone"
    t.string "account_type", default: "Student", null: false
    t.string "preferred_time_zone"
    t.boolean "temp_password", default: false
    t.string "slx_contact_id", limit: 16
    t.boolean "fake", default: false, null: false
    t.boolean "display_email", default: false
    t.boolean "archived", default: false
    t.boolean "registration_window_open", default: true
    t.boolean "pronto_activated", default: false, null: false
    t.datetime "pronto_activated_at"
    t.string "salesforce_id"
    t.boolean "active", default: true
    t.string "gender"
    t.string "guid"
    t.bigint "sync_token", default: 0
    t.string "request_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["first_name"], name: "index_users_on_first_name"
    t.index ["guid"], name: "index_users_on_guid", unique: true
    t.index ["last_name"], name: "index_users_on_last_name"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "vhldirect_package_types", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "package_label", null: false
    t.string "edelivery_attribute", null: false
  end

  create_table "vhldirect_programs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "program_id", null: false
    t.string "name", null: false
  end

  create_table "video_recordings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "recording_path"
    t.integer "user_id"
    t.string "uuid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "vitalsource_redemptions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "program_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "program_id"], name: "index_vitalsource_redemptions_on_user_id_and_program_id"
  end

  create_table "vocab_program_groups", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "vocab_tags", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "vocab_word_id"
    t.index ["vocab_word_id"], name: "by_vocab_word"
  end

  create_table "vocab_words", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.string "target_word", default: ""
    t.string "base_word", default: ""
    t.string "target_definition", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "archived", default: false, null: false
    t.integer "default_vocab_word_id"
    t.string "language"
    t.integer "lesson_id"
    t.integer "vocab_program_group_id"
    t.integer "recording_id"
    t.string "image_filename"
    t.integer "program_id"
    t.index ["user_id", "default_vocab_word_id"], name: "by_user_and_default_vocab_word"
  end

  create_table "worksets", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "section_id"
    t.text "activity_list"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "section_id"], name: "user_section"
  end

end
