class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :provider, :null => false
      t.string :uid,      :null => false
      t.string :email
      t.string :name
      t.string :avatar_url

      t.timestamps
    end

    add_index :users, [ :provider, :uid ], :unique => true
  end
end
