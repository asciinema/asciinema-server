defmodule Asciinema.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Asciinema.Accounts.User

  @valid_email_re ~r/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i
  @valid_username_re ~r/^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$/
  @valid_theme_names ["asciinema", "tango", "solarized-dark", "solarized-light", "monokai"]

  @timestamps_opts [type: :utc_datetime_usec]

  schema "users" do
    field :username, :string
    field :temporary_username, :string
    field :email, :string
    field :name, :string
    field :auth_token, :string
    field :theme_name, :string
    field :asciicasts_private_by_default, :boolean, default: true
    field :last_login_at, :utc_datetime_usec
    field :is_admin, :boolean

    timestamps()

    has_many :asciicasts, Asciinema.Recordings.Asciicast
    has_many :api_tokens, Asciinema.Accounts.ApiToken
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :name, :username, :theme_name, :asciicasts_private_by_default])
    |> validate_format(:email, @valid_email_re)
    |> validate_format(:username, @valid_username_re)
    |> validate_length(:username, min: 2, max: 16)
    |> validate_inclusion(:theme_name, @valid_theme_names)
    |> unique_constraint(:username, name: "index_users_on_username")
    |> unique_constraint(:email, name: "index_users_on_email")
  end

  def signup_changeset(attrs) do
    %User{}
    |> changeset(attrs)
    |> validate_required([:email])
  end

  def update_changeset(%User{} = user, attrs) do
    user
    |> changeset(attrs)
    |> validate_required([:username, :email])
  end

  def temporary_changeset(temporary_username) do
    change(%User{}, %{temporary_username: temporary_username})
  end
end
