defmodule Asciinema.Accounts.Cli do
  use Ecto.Schema
  alias Asciinema.Accounts.User

  @timestamps_opts [type: :utc_datetime_usec]

  schema "clis" do
    field :token, :string
    field :revoked_at, :utc_datetime_usec

    timestamps()

    belongs_to :user, User
  end
end
