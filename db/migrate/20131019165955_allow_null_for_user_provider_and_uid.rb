class AllowNullForUserProviderAndUid < ActiveRecord::Migration
  def change
    change_column :users, :provider, :string, null: true
    change_column :users, :uid, :string, null: true
  end
end
