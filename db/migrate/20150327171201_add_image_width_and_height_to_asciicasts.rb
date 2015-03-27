class AddImageWidthAndHeightToAsciicasts < ActiveRecord::Migration
  def change
    add_column :asciicasts, :image_width, :integer
    add_column :asciicasts, :image_height, :integer
  end
end
