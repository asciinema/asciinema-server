class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.text :body
      t.integer :user_id
      t.integer :asciicast_id

      t.timestamps
    end

    add_index(:comments, :asciicast_id)
    add_index(:comments, :user_id)
  end
end
