class AddStdinStderrToAsciicast < ActiveRecord::Migration
  def change
    add_column :asciicasts, :stdin, :string
    add_column :asciicasts, :stdin_timing, :string
    add_column :asciicasts, :stdout, :string
    add_column :asciicasts, :stdout_timing, :string
  end
end
