class AddCommentsCountToAsciicast < ActiveRecord::Migration
  def change
    add_column :asciicasts, :comments_count, :integer, :null => false, :default => 0
  end
end
