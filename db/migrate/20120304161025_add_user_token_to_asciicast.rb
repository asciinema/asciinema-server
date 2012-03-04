class AddUserTokenToAsciicast < ActiveRecord::Migration
  def change
    add_column :asciicasts, :user_token, :string

    add_index :asciicasts, :user_token
  end
end
