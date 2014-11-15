class AddIndexOnAsciicastsPrivate < ActiveRecord::Migration
  def change
    add_index :asciicasts, :private
  end
end
