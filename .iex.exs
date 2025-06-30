import_if_available(Ecto)
import_if_available(Ecto.Query)
import_if_available(Ecto.Changeset)
import_if_available(Enum, only: [map: 2, filter: 2, reduce: 2, reduce: 3])

alias Asciinema.{Repo, Recordings, Accounts}
alias Asciinema.Recordings.Asciicast
alias Asciinema.Accounts.{User, Cli}
