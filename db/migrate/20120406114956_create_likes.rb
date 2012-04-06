class CreateLikes < ActiveRecord::Migration
  def change
    create_table :likes do |t|
      t.integer :asciicast_id, :null => false
      t.integer :user_id, :null => false

      t.timestamps
    end

    add_index :likes, :asciicast_id
    add_index :likes, :user_id
    add_index :likes, [:user_id, :asciicast_id]
  end
end
