class RenameAsciicastsStdinAndStdout < ActiveRecord::Migration
  def up
    rename_column :asciicasts, :stdin, :stdin_data
    rename_column :asciicasts, :stdout, :stdout_data
  end

  def down
    rename_column :asciicasts, :stdin_data, :stdin
    rename_column :asciicasts, :stdout_data, :stdout
  end
end
