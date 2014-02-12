class RemoveUsernameAndApiTokenFromAsciicasts < ActiveRecord::Migration
  def change
    remove_column :asciicasts, :username
    remove_column :asciicasts, :api_token
  end
end
