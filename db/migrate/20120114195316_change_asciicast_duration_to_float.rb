class ChangeAsciicastDurationToFloat < ActiveRecord::Migration
  def up
    change_column :asciicasts, :duration, :float, :null => false
  end

  def down
    change_column :asciicasts, :duration, :integer, :null => false
  end
end
