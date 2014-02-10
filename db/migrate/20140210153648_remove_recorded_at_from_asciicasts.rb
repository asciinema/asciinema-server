class RemoveRecordedAtFromAsciicasts < ActiveRecord::Migration
  def change
    remove_column :asciicasts, :recorded_at
  end
end
