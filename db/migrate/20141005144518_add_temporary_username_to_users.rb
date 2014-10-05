class AddTemporaryUsernameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :temporary_username, :string
  end
end
