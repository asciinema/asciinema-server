class RenameUserTokensToApiTokens < ActiveRecord::Migration
  def change
    rename_table :user_tokens, :api_tokens
    rename_column :asciicasts, :user_token, :api_token
  end
end
