class RemoveDefaultFromAsciicastsVersion < ActiveRecord::Migration
  def change
    change_column_default :asciicasts, :version, nil
  end
end
