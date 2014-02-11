class AddDummyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :dummy, :boolean, default: false, null: false
    add_index :users, :dummy
  end
end
