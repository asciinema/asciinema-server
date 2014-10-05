class RemoveDummyFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :dummy
  end
end
