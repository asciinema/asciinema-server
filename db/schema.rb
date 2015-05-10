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

ActiveRecord::Schema.define(version: 20150510162214) do

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
    t.integer  "likes_count",      default: 0,     null: false
    t.text     "snapshot"
    t.integer  "comments_count",   default: 0,     null: false
    t.boolean  "time_compression", default: true,  null: false
    t.integer  "views_count",      default: 0,     null: false
    t.string   "stdout_frames"
    t.string   "user_agent"
    t.string   "theme_name"
    t.float    "snapshot_at"
    t.integer  "version",                          null: false
    t.string   "file"
    t.string   "image"
    t.integer  "image_width"
    t.integer  "image_height"
    t.string   "secret_token",                     null: false
    t.boolean  "private",          default: false, null: false
  end

  add_index "asciicasts", ["created_at"], name: "index_asciicasts_on_created_at", using: :btree
  add_index "asciicasts", ["featured"], name: "index_asciicasts_on_featured", using: :btree
  add_index "asciicasts", ["likes_count"], name: "index_asciicasts_on_likes_count", using: :btree
  add_index "asciicasts", ["private"], name: "index_asciicasts_on_private", using: :btree
  add_index "asciicasts", ["secret_token"], name: "index_asciicasts_on_secret_token", unique: true, using: :btree
  add_index "asciicasts", ["user_id"], name: "index_asciicasts_on_user_id", using: :btree
  add_index "asciicasts", ["views_count"], name: "index_asciicasts_on_views_count", using: :btree

  create_table "comments", force: true do |t|
    t.text     "body",         null: false
    t.integer  "user_id",      null: false
    t.integer  "asciicast_id", null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "comments", ["asciicast_id", "created_at"], name: "index_comments_on_asciicast_id_and_created_at", using: :btree
  add_index "comments", ["asciicast_id"], name: "index_comments_on_asciicast_id", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "expiring_tokens", force: true do |t|
    t.integer  "user_id",    null: false
    t.string   "token",      null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at"
    t.datetime "used_at"
  end

  add_index "expiring_tokens", ["used_at", "expires_at", "token"], name: "index_expiring_tokens_on_used_at_and_expires_at_and_token", using: :btree
  add_index "expiring_tokens", ["user_id"], name: "index_expiring_tokens_on_user_id", using: :btree

  create_table "likes", force: true do |t|
    t.integer  "asciicast_id", null: false
    t.integer  "user_id",      null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "likes", ["asciicast_id"], name: "index_likes_on_asciicast_id", using: :btree
  add_index "likes", ["user_id", "asciicast_id"], name: "index_likes_on_user_id_and_asciicast_id", using: :btree
  add_index "likes", ["user_id"], name: "index_likes_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "email"
    t.string   "name"
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.string   "username"
    t.string   "auth_token"
    t.string   "theme_name"
    t.string   "temporary_username"
    t.boolean  "asciicasts_private_by_default", default: false, null: false
  end

  add_index "users", ["auth_token"], name: "index_users_on_auth_token", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", using: :btree

  add_foreign_key "api_tokens", "users", name: "api_tokens_user_id_fk"

  add_foreign_key "asciicasts", "users", name: "asciicasts_user_id_fk"

  add_foreign_key "comments", "asciicasts", name: "comments_asciicast_id_fk"
  add_foreign_key "comments", "users", name: "comments_user_id_fk"

  add_foreign_key "expiring_tokens", "users", name: "expiring_tokens_user_id_fk"

  add_foreign_key "likes", "asciicasts", name: "likes_asciicast_id_fk"
  add_foreign_key "likes", "users", name: "likes_user_id_fk"

end
