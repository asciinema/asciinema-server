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

ActiveRecord::Schema.define(version: 20130828162232) do

  create_table "asciicasts", force: true do |t|
    t.integer  "user_id"
    t.string   "title"
    t.float    "duration",                         null: false
    t.datetime "recorded_at"
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
    t.string   "user_token"
    t.text     "description"
    t.boolean  "featured",         default: false
    t.string   "username"
    t.integer  "likes_count",      default: 0,     null: false
    t.text     "snapshot"
    t.integer  "comments_count",   default: 0,     null: false
    t.boolean  "time_compression", default: true,  null: false
    t.integer  "views_count",      default: 0,     null: false
    t.string   "stdout_frames"
  end

  add_index "asciicasts", ["created_at"], name: "index_asciicasts_on_created_at", using: :btree
  add_index "asciicasts", ["featured"], name: "index_asciicasts_on_featured", using: :btree
  add_index "asciicasts", ["likes_count"], name: "index_asciicasts_on_likes_count", using: :btree
  add_index "asciicasts", ["recorded_at"], name: "index_asciicasts_on_recorded_at", using: :btree
  add_index "asciicasts", ["user_id"], name: "index_asciicasts_on_user_id", using: :btree
  add_index "asciicasts", ["user_token"], name: "index_asciicasts_on_user_token", using: :btree
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

  create_table "likes", force: true do |t|
    t.integer  "asciicast_id", null: false
    t.integer  "user_id",      null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "likes", ["asciicast_id"], name: "index_likes_on_asciicast_id", using: :btree
  add_index "likes", ["user_id", "asciicast_id"], name: "index_likes_on_user_id_and_asciicast_id", using: :btree
  add_index "likes", ["user_id"], name: "index_likes_on_user_id", using: :btree

  create_table "user_tokens", force: true do |t|
    t.integer  "user_id",    null: false
    t.string   "token",      null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "user_tokens", ["token"], name: "index_user_tokens_on_token", using: :btree
  add_index "user_tokens", ["user_id"], name: "index_user_tokens_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "provider",   null: false
    t.string   "uid",        null: false
    t.string   "email"
    t.string   "name"
    t.string   "avatar_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "nickname",   null: false
  end

  add_index "users", ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true, using: :btree

end
