defmodule Asciinema.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Asciinema.Accounts.User

  @valid_email_re ~r/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i

  schema "users" do
    field :username, :string
    field :temporary_username, :string
    field :email, :string
    field :name, :string
    field :auth_token, :string
    field :theme_name, :string
    field :asciicasts_private_by_default, :boolean, default: true
    field :last_login_at, Timex.Ecto.DateTime

    timestamps(inserted_at: :created_at)

    has_many :asciicasts, Asciinema.Asciicasts.Asciicast
    has_many :api_tokens, Asciinema.Accounts.ApiToken
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :name, :username, :theme_name, :asciicasts_private_by_default])
    |> validate_format(:email, @valid_email_re)
  end

  def create_changeset(struct, attrs) do
    struct
    |> changeset(attrs)
    |> generate_auth_token
  end

  def signup_changeset(attrs) do
    %User{}
    |> create_changeset(attrs)
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> unique_constraint(:email, name: "index_users_on_email")
  end

  def login_changeset(user) do
    change(user, %{last_login_at: Timex.now()})
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
