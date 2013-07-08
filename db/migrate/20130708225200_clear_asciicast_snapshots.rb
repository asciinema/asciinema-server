class ClearAsciicastSnapshots < ActiveRecord::Migration
  def up
    execute "UPDATE asciicasts SET snapshot = NULL"
  end

  def down
  end
end
