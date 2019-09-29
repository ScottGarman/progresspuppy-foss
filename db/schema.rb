# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_09_13_181757) do

  create_table "quotes", force: :cascade do |t|
    t.string "quotation", null: false
    t.string "source", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_quotes_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.boolean "display_quotes", default: true
    t.boolean "burnination", default: false
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_settings_on_user_id"
  end

  create_table "task_categories", force: :cascade do |t|
    t.string "name", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_task_categories_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "summary", null: false
    t.integer "task_category_id"
    t.integer "priority", default: 3, null: false
    t.string "status", default: "INCOMPLETE", null: false
    t.date "due_at"
    t.datetime "completed_at"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["task_category_id"], name: "index_tasks_on_task_category_id"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name", limit: 50, null: false
    t.string "last_name", limit: 50, null: false
    t.string "email", limit: 80, null: false
    t.string "password_digest", limit: 80, null: false
    t.boolean "email_confirmed", default: false
    t.datetime "last_login_at"
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "remember_digest"
    t.string "activation_digest"
    t.boolean "activated", default: false
    t.datetime "activated_at"
    t.string "reset_digest"
    t.datetime "reset_sent_at"
    t.string "time_zone"
    t.datetime "accepted_tos_at"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

end
