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

ActiveRecord::Schema[8.0].define(version: 2026_02_17_014921) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "icon"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "device_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token", null: false
    t.string "platform", null: false
    t.string "device_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_device_tokens_on_token", unique: true
    t.index ["user_id"], name: "index_device_tokens_on_user_id"
  end

  create_table "household_members", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "household_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["household_id"], name: "index_household_members_on_household_id"
    t.index ["role"], name: "index_household_members_on_role"
    t.index ["user_id", "household_id"], name: "index_household_members_on_user_id_and_household_id", unique: true
    t.index ["user_id"], name: "index_household_members_on_user_id"
  end

  create_table "households", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "inventory_items", force: :cascade do |t|
    t.bigint "household_id", null: false
    t.bigint "item_id"
    t.string "custom_name"
    t.decimal "quantity", precision: 10, scale: 2, default: "0.0", null: false
    t.bigint "unit_type_id"
    t.decimal "low_stock_threshold", precision: 10, scale: 2, default: "0.0", null: false
    t.bigint "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_inventory_items_on_created_by_id"
    t.index ["household_id", "custom_name"], name: "index_inventory_items_on_household_id_and_custom_name", unique: true, where: "(custom_name IS NOT NULL)"
    t.index ["household_id", "item_id"], name: "index_inventory_items_on_household_id_and_item_id", unique: true, where: "(item_id IS NOT NULL)"
    t.index ["household_id"], name: "index_inventory_items_on_household_id"
    t.index ["item_id"], name: "index_inventory_items_on_item_id"
    t.index ["unit_type_id"], name: "index_inventory_items_on_unit_type_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.bigint "household_id", null: false
    t.string "email", null: false
    t.string "token", null: false
    t.integer "status", default: 0, null: false
    t.bigint "invited_by_id", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_invitations_on_email"
    t.index ["household_id", "email"], name: "index_invitations_on_household_and_email_pending", unique: true, where: "(status = 0)"
    t.index ["household_id"], name: "index_invitations_on_household_id"
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["status"], name: "index_invitations_on_status"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "items", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "brand"
    t.string "icon"
    t.boolean "is_default", default: false, null: false
    t.bigint "category_id", null: false
    t.bigint "default_unit_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_items_on_category_id"
    t.index ["default_unit_type_id"], name: "index_items_on_default_unit_type_id"
    t.index ["is_default"], name: "index_items_on_is_default"
    t.index ["name", "category_id"], name: "index_items_on_name_and_category_id", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "notifiable_type"
    t.bigint "notifiable_id"
    t.string "notification_type", null: false
    t.string "title", null: false
    t.text "body"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.string "scopes"
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "shopping_list_items", force: :cascade do |t|
    t.bigint "shopping_list_id", null: false
    t.bigint "item_id"
    t.string "custom_name"
    t.decimal "quantity", precision: 10, scale: 2, default: "1.0", null: false
    t.bigint "unit_type_id"
    t.integer "status", default: 0, null: false
    t.bigint "added_by_id", null: false
    t.datetime "checked_at"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["added_by_id"], name: "index_shopping_list_items_on_added_by_id"
    t.index ["item_id"], name: "index_shopping_list_items_on_item_id"
    t.index ["shopping_list_id", "position"], name: "index_shopping_list_items_on_shopping_list_id_and_position"
    t.index ["shopping_list_id"], name: "index_shopping_list_items_on_shopping_list_id"
    t.index ["status"], name: "index_shopping_list_items_on_status"
    t.index ["unit_type_id"], name: "index_shopping_list_items_on_unit_type_id"
  end

  create_table "shopping_lists", force: :cascade do |t|
    t.bigint "household_id", null: false
    t.string "name", null: false
    t.integer "status", default: 0, null: false
    t.bigint "created_by_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_recurring", default: false, null: false
    t.string "recurrence_pattern"
    t.integer "recurrence_day"
    t.datetime "next_recurrence_at"
    t.bigint "parent_shopping_list_id"
    t.index ["created_by_id"], name: "index_shopping_lists_on_created_by_id"
    t.index ["household_id"], name: "index_shopping_lists_on_household_id"
    t.index ["next_recurrence_at"], name: "index_shopping_lists_on_next_recurrence_at", where: "((is_recurring = true) AND (next_recurrence_at IS NOT NULL))"
    t.index ["parent_shopping_list_id"], name: "index_shopping_lists_on_parent_shopping_list_id"
    t.index ["status"], name: "index_shopping_lists_on_status"
  end

  create_table "unit_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "abbreviation", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["abbreviation"], name: "index_unit_types_on_abbreviation", unique: true
    t.index ["name"], name: "index_unit_types_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email_confirmation_otp_digest"
    t.datetime "email_confirmation_otp_sent_at"
    t.datetime "email_confirmed_at"
    t.integer "email_confirmation_attempts", default: 0, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["email_confirmed_at"], name: "index_users_on_email_confirmed_at"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "device_tokens", "users"
  add_foreign_key "household_members", "households"
  add_foreign_key "household_members", "users"
  add_foreign_key "inventory_items", "households"
  add_foreign_key "inventory_items", "items"
  add_foreign_key "inventory_items", "unit_types"
  add_foreign_key "inventory_items", "users", column: "created_by_id"
  add_foreign_key "invitations", "households"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "items", "categories"
  add_foreign_key "items", "unit_types", column: "default_unit_type_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "shopping_list_items", "items"
  add_foreign_key "shopping_list_items", "shopping_lists"
  add_foreign_key "shopping_list_items", "unit_types"
  add_foreign_key "shopping_list_items", "users", column: "added_by_id"
  add_foreign_key "shopping_lists", "households"
  add_foreign_key "shopping_lists", "shopping_lists", column: "parent_shopping_list_id"
  add_foreign_key "shopping_lists", "users", column: "created_by_id"
end
