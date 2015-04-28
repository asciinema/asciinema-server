class AddSupporterToUsers < ActiveRecord::Migration
  def change
    add_column :users, :supporter, :boolean, null: false, default: false
  end
end
