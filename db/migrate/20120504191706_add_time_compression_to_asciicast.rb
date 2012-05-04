class AddTimeCompressionToAsciicast < ActiveRecord::Migration
  def change
    add_column :asciicasts, :time_compression, :boolean, :null => false, :default => true
  end
end
