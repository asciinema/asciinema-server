class AddNicknameColumnToUsersTable < ActiveRecord::Migration
  def change
    add_column :users, :nickname, :string, :null => false
  end
end
