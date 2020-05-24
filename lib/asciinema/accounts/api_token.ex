defmodule Asciinema.Accounts.ApiToken do
  use Ecto.Schema
  import Ecto.Changeset
  alias Asciinema.Accounts.{ApiToken, User}

  @timestamps_opts [type: :utc_datetime_usec]

  schema "api_tokens" do
    field :token, :string
    field :revoked_at, :utc_datetime_usec

    timestamps(inserted_at: :created_at)

    belongs_to :user, User
  end

  @uuid4 ~r/\A[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\z/

  def create_changeset(%ApiToken{} = api_token, token) do
    api_token
    |> change(%{token: token})
    |> validate_format(:token, @uuid4)
    |> unique_constraint(:token, name: "index_api_tokens_on_token")
  end

  def revoke_changeset(%ApiToken{revoked_at: nil} = api_token) do
    change(api_token, %{revoked_at: Timex.now()})
  end

  def revoke_changeset(%ApiToken{} = api_token) do
    change(api_token)
  end
end
