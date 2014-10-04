class RenameTemporaryTokensToExpiringTokens < ActiveRecord::Migration
  def change
    rename_table :temporary_tokens, :expiring_tokens
  end
end
