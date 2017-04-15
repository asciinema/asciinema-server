# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

# Create asciinema user

asciinema_user = User.find_by_username("asciinema") || User.create!(username: "asciinema", name: "asciinema", email: "support@asciinema.org")

# Create "welcome" asciicast

if asciinema_user.asciicasts.count == 0
  attrs = AsciicastParams.build(File.open("resources/welcome.json"), asciinema_user, nil)
  AsciicastCreator.new.create(attrs.merge(private: false, snapshot_at: 76.2))
end
