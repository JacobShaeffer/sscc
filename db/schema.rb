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

ActiveRecord::Schema[7.0].define(version: 2023_03_23_192403) do
  create_table "content_metadata", force: :cascade do |t|
    t.integer "content_id"
    t.integer "metadatum_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contents", force: :cascade do |t|
    t.string "title"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "file"
    t.integer "copyright_permission_id"
    t.index ["copyright_permission_id"], name: "index_contents_on_copyright_permission_id"
    t.index ["user_id"], name: "index_contents_on_user_id"
  end

  create_table "copyright_permissions", force: :cascade do |t|
    t.text "description"
    t.integer "organization_id", null: false
    t.boolean "granted"
    t.date "date_contacted"
    t.date "date_of_response"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_copyright_permissions_on_organization_id"
    t.index ["user_id"], name: "index_copyright_permissions_on_user_id"
  end

  create_table "metadata", force: :cascade do |t|
    t.string "name"
    t.integer "metadata_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["metadata_type_id"], name: "index_metadata_on_metadata_type_id"
  end

  create_table "metadata_types", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.string "website"
    t.string "email"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_organizations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "contents", "copyright_permissions"
  add_foreign_key "contents", "users"
  add_foreign_key "copyright_permissions", "organizations"
  add_foreign_key "copyright_permissions", "users"
  add_foreign_key "metadata", "metadata_types"
  add_foreign_key "organizations", "users"
end
