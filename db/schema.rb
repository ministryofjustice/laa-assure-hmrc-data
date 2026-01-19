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

ActiveRecord::Schema[8.1].define(version: 2023_11_21_093241) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bulk_submissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.datetime "expires_at"
    t.string "status"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["discarded_at"], name: "index_bulk_submissions_on_discarded_at"
    t.index ["user_id"], name: "index_bulk_submissions_on_user_id"
  end

  create_table "malware_scan_results", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "file_details"
    t.text "scan_result"
    t.boolean "scanner_working"
    t.datetime "updated_at", null: false
    t.uuid "uploader_id"
    t.string "uploader_type"
    t.boolean "virus_found", null: false
    t.index ["uploader_type", "uploader_id"], name: "index_malware_scan_results_on_uploader"
  end

  create_table "submissions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "bulk_submission_id"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.datetime "dob"
    t.string "first_name", default: "", null: false
    t.uuid "hmrc_interface_id"
    t.jsonb "hmrc_interface_result", default: "{}", null: false
    t.string "last_name", default: "", null: false
    t.string "nino", default: "", null: false
    t.datetime "period_end_at"
    t.datetime "period_start_at"
    t.string "status", default: "", null: false
    t.datetime "updated_at", null: false
    t.string "use_case", null: false
    t.index ["bulk_submission_id"], name: "index_submissions_on_bulk_submission_id"
    t.index ["discarded_at"], name: "index_submissions_on_discarded_at"
    t.index ["hmrc_interface_id"], name: "index_submissions_on_hmrc_interface_id", unique: true
    t.index ["hmrc_interface_result"], name: "index_submissions_on_hmrc_interface_result", using: :gin
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "auth_provider", default: "", null: false
    t.string "auth_subject_uid"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.datetime "discarded_at"
    t.citext "email", default: "", null: false
    t.string "first_name", default: "", null: false
    t.string "last_name", default: "", null: false
    t.datetime "last_sign_in_at", precision: nil
    t.string "last_sign_in_ip"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["auth_subject_uid", "auth_provider"], name: "index_users_on_auth_subject_uid_and_auth_provider", unique: true
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bulk_submissions", "users"
  add_foreign_key "submissions", "bulk_submissions"
end
