class AddKeys < ActiveRecord::Migration
  def change
    add_foreign_key "api_tokens", "users", name: "api_tokens_user_id_fk"
    add_foreign_key "asciicasts", "users", name: "asciicasts_user_id_fk"
    add_foreign_key "comments", "asciicasts", name: "comments_asciicast_id_fk"
    add_foreign_key "comments", "users", name: "comments_user_id_fk"
    add_foreign_key "expiring_tokens", "users", name: "expiring_tokens_user_id_fk"
    add_foreign_key "likes", "asciicasts", name: "likes_asciicast_id_fk"
    add_foreign_key "likes", "users", name: "likes_user_id_fk"
  end
end
