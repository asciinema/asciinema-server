class CreateAsciicasts < ActiveRecord::Migration
  def change
    create_table :asciicasts do |t|
      t.integer :user_id
      t.string :title
      t.integer :duration, :null => false
      t.datetime :recorded_at
      t.string :terminal_type
      t.integer :terminal_columns, :null => false
      t.integer :terminal_lines, :null => false
      t.string :command
      t.string :shell
      t.string :uname

      t.timestamps
    end

    add_index :asciicasts, :user_id
    add_index :asciicasts, :created_at
    add_index :asciicasts, :recorded_at
  end
end
