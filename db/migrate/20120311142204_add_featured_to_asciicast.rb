class AddFeaturedToAsciicast < ActiveRecord::Migration
  def change
    add_column :asciicasts, :featured, :boolean, :default => false

    add_index :asciicasts, :featured
  end
end
