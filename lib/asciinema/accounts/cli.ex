defmodule Asciinema.Accounts.Cli do
  use Ecto.Schema

  schema "clis" do
    field :token, :string
    field :revoked_at, :utc_datetime

    timestamps(type: :utc_datetime)

    belongs_to :user, Asciinema.Accounts.User
    has_many :asciicasts, Asciinema.Recordings.Asciicast
  end
end
