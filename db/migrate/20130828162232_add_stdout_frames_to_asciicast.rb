class AddStdoutFramesToAsciicast < ActiveRecord::Migration
  def change
    add_column :asciicasts, :stdout_frames, :string
  end
end
