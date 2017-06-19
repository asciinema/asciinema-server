class RemoveImageFromAsciicasts < ActiveRecord::Migration
  def change
    remove_column :asciicasts, :image
    remove_column :asciicasts, :image_width
    remove_column :asciicasts, :image_height
  end
end
