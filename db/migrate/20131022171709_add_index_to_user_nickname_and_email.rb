class AddIndexToUserNicknameAndEmail < ActiveRecord::Migration
  def change
    add_index :users, :nickname
    add_index :users, :email
  end
end
