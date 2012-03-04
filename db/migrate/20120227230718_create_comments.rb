class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.text :body, :null => false
      t.integer :user_id, :null => false
      t.integer :asciicast_id, :null => false

      t.timestamps
    end

    add_index(:comments, :asciicast_id)
    add_index(:comments, :user_id)
  end
end
