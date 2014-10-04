class RenameTemporaryTokensCodeToToken < ActiveRecord::Migration
  def change
    rename_column :temporary_tokens, :code, :token
  end
end
