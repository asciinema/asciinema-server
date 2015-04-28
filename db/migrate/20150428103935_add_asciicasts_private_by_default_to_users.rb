class AddAsciicastsPrivateByDefaultToUsers < ActiveRecord::Migration
  def change
    add_column :users, :asciicasts_private_by_default, :boolean, null: false, default: false
  end
end
