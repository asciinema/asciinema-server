class AddSnapshotToAsciicast < ActiveRecord::Migration
  def change
    add_column :asciicasts, :snapshot, :text

  end
end
