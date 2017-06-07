ExUnit.configure exclude: [a2png: true]
ExUnit.start

Ecto.Adapters.SQL.Sandbox.mode(Asciinema.Repo, :manual)
