class AddVersionToAsciicasts < ActiveRecord::Migration
  def change
    add_column :asciicasts, :version, :integer, default: 0, null: false
  end
end
