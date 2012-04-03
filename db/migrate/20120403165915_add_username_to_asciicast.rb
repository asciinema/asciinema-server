class AddUsernameToAsciicast < ActiveRecord::Migration
  def change
    add_column :asciicasts, :username, :string
  end
end
