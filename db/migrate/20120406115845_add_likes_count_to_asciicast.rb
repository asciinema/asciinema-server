class AddLikesCountToAsciicast < ActiveRecord::Migration
  def change
    add_column :asciicasts, :likes_count, :integer
    add_index  :asciicasts, :likes_count
  end
end
