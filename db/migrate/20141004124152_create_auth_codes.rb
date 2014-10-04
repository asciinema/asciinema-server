class CreateAuthCodes < ActiveRecord::Migration
  def change
    create_table :auth_codes do |t|
      t.references :user, index: true, null: false
      t.string :code, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :auth_codes, [:code, :expires_at]
  end
end
