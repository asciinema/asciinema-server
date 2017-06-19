class RemoveCommentsAndLikes < ActiveRecord::Migration
  def change
    remove_column :asciicasts, :comments_count
    remove_column :asciicasts, :likes_count
    drop_table :comments
    drop_table :likes
  end
end
