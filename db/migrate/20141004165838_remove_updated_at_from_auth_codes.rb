class RemoveUpdatedAtFromAuthCodes < ActiveRecord::Migration
  def change
    remove_column :auth_codes, :updated_at
  end
end
