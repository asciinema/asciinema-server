class AddViewsCountToAsciicast < ActiveRecord::Migration
  def change
    add_column :asciicasts, :views_count, :integer, :null => false, :default => 0
  end
end
