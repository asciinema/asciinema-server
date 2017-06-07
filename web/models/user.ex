defmodule Asciinema.User do
  use Asciinema.Web, :model

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
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :name, :username, :temporary_username, :auth_token, :theme_name, :asciicasts_private_by_default])
    |> validate_required([:auth_token])
  end
end
