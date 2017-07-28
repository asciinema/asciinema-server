# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170728221839) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "api_tokens", force: true do |t|
    t.integer  "user_id",    null: false
    t.string   "token",      null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "revoked_at"
  end

  add_index "api_tokens", ["token"], name: "index_api_tokens_on_token", using: :btree
  add_index "api_tokens", ["user_id"], name: "index_api_tokens_on_user_id", using: :btree

  create_table "asciicasts", force: true do |t|
    t.integer  "user_id"
    t.string   "title"
    t.float    "duration",                         null: false
    t.string   "terminal_type"
    t.integer  "terminal_columns",                 null: false
    t.integer  "terminal_lines",                   null: false
    t.string   "command"
    t.string   "shell"
    t.string   "uname"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.string   "stdin_data"
    t.string   "stdin_timing"
    t.string   "stdout_data"
    t.string   "stdout_timing"
    t.text     "description"
    t.boolean  "featured",         default: false
    t.text     "snapshot"
    t.boolean  "time_compression", default: true,  null: false
    t.integer  "views_count",      default: 0,     null: false
    t.string   "stdout_frames"
    t.string   "user_agent"
    t.string   "theme_name"
    t.float    "snapshot_at"
    t.integer  "version",                          null: false
    t.string   "file"
    t.string   "secret_token",                     null: false
    t.boolean  "private",          default: false, null: false
  end

  add_index "asciicasts", ["created_at"], name: "index_asciicasts_on_created_at", using: :btree
  add_index "asciicasts", ["featured"], name: "index_asciicasts_on_featured", using: :btree
  add_index "asciicasts", ["private"], name: "index_asciicasts_on_private", using: :btree
  add_index "asciicasts", ["secret_token"], name: "index_asciicasts_on_secret_token", unique: true, using: :btree
  add_index "asciicasts", ["user_id"], name: "index_asciicasts_on_user_id", using: :btree
  add_index "asciicasts", ["views_count"], name: "index_asciicasts_on_views_count", using: :btree

  create_table "users", force: true do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "email"
    t.string   "name"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.string   "username"
    t.string   "auth_token"
    t.string   "theme_name"
    t.string   "temporary_username"
    t.boolean  "asciicasts_private_by_default", default: true, null: false
    t.datetime "last_login_at"
  end

  add_index "users", ["auth_token"], name: "index_users_on_auth_token", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", using: :btree

  Foreigner.load
  add_foreign_key "api_tokens", "users", name: "api_tokens_user_id_fk"

  add_foreign_key "asciicasts", "users", name: "asciicasts_user_id_fk"

end
