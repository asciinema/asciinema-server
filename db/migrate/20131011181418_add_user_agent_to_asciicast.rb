class AddUserAgentToAsciicast < ActiveRecord::Migration
  def change
    add_column :asciicasts, :user_agent, :string
  end
end
