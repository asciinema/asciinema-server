class AddDescriptionToAsciicast < ActiveRecord::Migration
  def change
    add_column :asciicasts, :description, :text

  end
end
