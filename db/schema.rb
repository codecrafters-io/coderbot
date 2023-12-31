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

ActiveRecord::Schema[7.0].define(version: 2023_12_07_164122) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "autofix_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "status", null: false
    t.string "repository_clone_url", null: false
    t.string "submission_commit_sha", null: false
    t.string "last_successful_submission_commit_sha"
    t.string "language_slug", null: false
    t.string "course_slug", null: false
    t.string "course_stage_slug", null: false
    t.string "logstream_url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "steps_count"
    t.integer "duration_ms"
    t.string "error_message"
    t.string "codecrafters_server_url"
    t.text "explanation_markdown"
    t.jsonb "changed_files"
  end

end
