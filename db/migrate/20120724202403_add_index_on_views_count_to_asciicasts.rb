class AddIndexOnViewsCountToAsciicasts < ActiveRecord::Migration
  def change
    add_index :asciicasts, :views_count
  end
end
