class AddSecretTokenToAsciicasts < ActiveRecord::Migration
  def change
    add_column :asciicasts, :secret_token, :string

    Asciicast.find_each do |asciicast|
      asciicast.update_attribute(:secret_token, Asciicast.generate_secret_token)
    end

    change_column :asciicasts, :secret_token, :string, null: false
  end
end
