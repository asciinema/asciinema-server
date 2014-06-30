class RenameUsersThemeToThemeName < ActiveRecord::Migration
  def change
    rename_column :users, :theme, :theme_name
  end
end
