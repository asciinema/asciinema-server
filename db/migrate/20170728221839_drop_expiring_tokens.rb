class DropExpiringTokens < ActiveRecord::Migration
  def change
    drop_table :expiring_tokens
  end
end
