class AddThemeToAsciicasts < ActiveRecord::Migration
  def change
    add_column :asciicasts, :theme, :string
  end
end
