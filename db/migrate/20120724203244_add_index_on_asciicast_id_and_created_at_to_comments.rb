class AddIndexOnAsciicastIdAndCreatedAtToComments < ActiveRecord::Migration
  def change
    add_index :comments, [:asciicast_id, :created_at]
  end
end
