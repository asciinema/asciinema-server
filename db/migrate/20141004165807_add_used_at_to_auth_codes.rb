class AddUsedAtToAuthCodes < ActiveRecord::Migration
  def change
    add_column :auth_codes, :used_at, :datetime
  end
end
