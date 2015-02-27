class AddFileToAsciicast < ActiveRecord::Migration
  def change
    add_column :asciicasts, :file, :string
  end
end
