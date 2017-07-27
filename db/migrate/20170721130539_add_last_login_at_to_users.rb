class AddLastLoginAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_login_at, :datetime
  end
end
