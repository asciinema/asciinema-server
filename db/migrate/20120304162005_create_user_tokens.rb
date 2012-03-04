class CreateUserTokens < ActiveRecord::Migration
  def change
    create_table :user_tokens do |t|
      t.integer :user_id, :null => false
      t.string :token, :null => false

      t.timestamps
    end

    add_index :user_tokens, :user_id
    add_index :user_tokens, :token
  end
end
