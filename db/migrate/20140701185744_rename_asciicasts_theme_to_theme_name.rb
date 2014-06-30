class RenameAsciicastsThemeToThemeName < ActiveRecord::Migration
  def change
    rename_column :asciicasts, :theme, :theme_name
  end
end
