{:ok, _} = Application.ensure_all_started(:ex_machina)

ExUnit.configure exclude: [rsvg: true, vt: true]
ExUnit.start

Ecto.Adapters.SQL.Sandbox.mode(Asciinema.Repo, :manual)
