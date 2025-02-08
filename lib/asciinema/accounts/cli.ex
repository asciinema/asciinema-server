defmodule Asciinema.Accounts.Cli do
  use Ecto.Schema
  import Ecto.Changeset
  alias Asciinema.Accounts.{Cli, User}

  @timestamps_opts [type: :utc_datetime_usec]

  schema "clis" do
    field :token, :string
    field :revoked_at, :utc_datetime_usec

    timestamps()

    belongs_to :user, User
  end

  @uuid4 ~r/\A[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\z/

  def create_changeset(%Cli{} = cli, token) do
    cli
    |> change(%{token: token})
    |> validate_format(:token, @uuid4)
    |> unique_constraint(:token, name: "clis_token_index")
  end

  def revoke_changeset(%Cli{revoked_at: nil} = cli) do
    change(cli, %{revoked_at: Timex.now()})
  end

  def revoke_changeset(%Cli{} = cli) do
    change(cli)
  end
end
