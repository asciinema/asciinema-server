defmodule Asciinema.Accounts.User do
  use Ecto.Schema

  @timestamps_opts [type: :utc_datetime_usec]

  schema "users" do
    field :username, :string
    field :temporary_username, :string
    field :email, :string
    field :name, :string
    field :auth_token, :string
    field :theme_name, :string
    field :theme_prefer_original, :boolean, default: true
    field :terminal_font_family, :string

    field :default_asciicast_visibility, Ecto.Enum,
      values: [:private, :unlisted, :public],
      default: :unlisted

    field :last_login_at, :utc_datetime_usec
    field :is_admin, :boolean

    timestamps()

    has_many :asciicasts, Asciinema.Recordings.Asciicast
    has_many :live_streams, Asciinema.Streaming.LiveStream
    has_many :api_tokens, Asciinema.Accounts.ApiToken
  end
end
