class ConvertEmptyStringThemeToNil < ActiveRecord::Migration
  def change
    execute "UPDATE users SET theme_name=NULL WHERE theme_name=''"
    execute "UPDATE asciicasts SET theme_name=NULL WHERE theme_name=''"
  end
end
