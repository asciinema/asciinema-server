class AddUniqueIndexToAsciicastsSecretToken < ActiveRecord::Migration
  def change
    add_index :asciicasts, :secret_token, unique: true
  end
end
