defmodule Asciinema.User do
  use Asciinema.Web, :model
  alias Asciinema.User

  schema "users" do
    field :username, :string
    field :temporary_username, :string
    field :email, :string
    field :name, :string
    field :auth_token, :string
    field :theme_name, :string
    field :asciicasts_private_by_default, :boolean, default: true

    timestamps(inserted_at: :created_at)

    has_many :asciicasts, Asciinema.Asciicast
    has_many :api_tokens, Asciinema.ApiToken
    has_many :expiring_tokens, Asciinema.ExpiringToken
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :name, :username, :theme_name, :asciicasts_private_by_default])
  end

  def create_changeset(struct, attrs) do
    struct
    |> changeset(attrs)
    |> validate_required(~w(username email)a)
    |> generate_auth_token
  end

  def temporary_changeset(temporary_username) do
    %User{}
    |> change(%{temporary_username: temporary_username})
    |> generate_auth_token
  end

  defp generate_auth_token(changeset) do
    put_change(changeset, :auth_token, Crypto.random_token(20))
  end
end
