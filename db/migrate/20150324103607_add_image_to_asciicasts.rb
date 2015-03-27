class AddImageToAsciicasts < ActiveRecord::Migration
  def change
    add_column :asciicasts, :image, :string
  end
end
