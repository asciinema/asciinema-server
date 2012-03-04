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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120304162005) do

  create_table "asciicasts", :force => true do |t|
    t.integer  "user_id"
    t.string   "title"
    t.float    "duration",         :null => false
    t.datetime "recorded_at"
    t.string   "terminal_type"
    t.integer  "terminal_columns", :null => false
    t.integer  "terminal_lines",   :null => false
    t.string   "command"
    t.string   "shell"
    t.string   "uname"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "stdin"
    t.string   "stdin_timing"
    t.string   "stdout"
    t.string   "stdout_timing"
    t.string   "user_token"
  end

  add_index "asciicasts", ["created_at"], :name => "index_asciicasts_on_created_at"
  add_index "asciicasts", ["recorded_at"], :name => "index_asciicasts_on_recorded_at"
  add_index "asciicasts", ["user_id"], :name => "index_asciicasts_on_user_id"
  add_index "asciicasts", ["user_token"], :name => "index_asciicasts_on_user_token"

  create_table "comments", :force => true do |t|
    t.text     "body",         :null => false
    t.integer  "user_id",      :null => false
    t.integer  "asciicast_id", :null => false
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "comments", ["asciicast_id"], :name => "index_comments_on_asciicast_id"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

  create_table "user_tokens", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.string   "token",      :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "user_tokens", ["token"], :name => "index_user_tokens_on_token"
  add_index "user_tokens", ["user_id"], :name => "index_user_tokens_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "provider",   :null => false
    t.string   "uid",        :null => false
    t.string   "email"
    t.string   "name"
    t.string   "avatar_url"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "nickname",   :null => false
  end

  add_index "users", ["provider", "uid"], :name => "index_users_on_provider_and_uid", :unique => true

end
