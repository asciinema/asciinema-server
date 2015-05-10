class ChangeUsersDefaultAsciicastPrivacyPolicy < ActiveRecord::Migration
  def up
    change_column :users, :asciicasts_private_by_default, :boolean, default: true, null: false
    execute "UPDATE users SET asciicasts_private_by_default = TRUE"
  end

  def down
    change_column :users, :asciicasts_private_by_default, :boolean, default: false, null: false
  end
end
