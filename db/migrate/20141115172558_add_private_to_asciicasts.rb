class AddPrivateToAsciicasts < ActiveRecord::Migration
  def change
    add_column :asciicasts, :private, :boolean, null: false, default: false
  end
end
