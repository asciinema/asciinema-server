class SetTemporaryUsernameOnUsers < ActiveRecord::Migration
  def change
    change_column :users, :username, :string, null: true
    execute "UPDATE users SET temporary_username = username WHERE dummy IS TRUE"
    execute "UPDATE users SET username = NULL WHERE dummy IS TRUE"
  end
end
