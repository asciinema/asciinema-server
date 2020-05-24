# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Asciinema.Repo.insert!(%Asciinema.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

user = Asciinema.Accounts.ensure_asciinema_user()
Asciinema.Asciicasts.ensure_welcome_asciicast(user)
