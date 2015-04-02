class AddRevokedAtToApiTokens < ActiveRecord::Migration
  def change
    add_column :api_tokens, :revoked_at, :datetime
  end
end
