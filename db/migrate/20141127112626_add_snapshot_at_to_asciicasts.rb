class AddSnapshotAtToAsciicasts < ActiveRecord::Migration
  def change
    add_column :asciicasts, :snapshot_at, :float
  end
end
