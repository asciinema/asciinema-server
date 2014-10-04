class UpdateAuthCodesIndex < ActiveRecord::Migration
  def change
    remove_index :auth_codes, name: "index_auth_codes_on_code_and_expires_at"
    add_index :auth_codes, [:used_at, :expires_at, :code]
  end
end
