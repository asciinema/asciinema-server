class RenameAuthCodesToTemporaryTokens < ActiveRecord::Migration
  def change
    rename_table :auth_codes, :temporary_tokens
  end
end
