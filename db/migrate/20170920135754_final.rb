class Final < ActiveRecord::Migration
  def change
    say ""
    say "Bye Rails migrations! Hello Ecto migrations!"
    say "From now on run the migrations with: mix ecto.migrate"
    say ""
  end
end
