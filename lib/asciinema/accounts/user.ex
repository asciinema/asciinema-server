defmodule Asciinema.Accounts.User do
  use Ecto.Schema

  @timestamps_opts [type: :utc_datetime_usec]

  schema "users" do
    field :username, :string
    field :temporary_username, :string
    field :email, :string
    field :name, :string
    field :auth_token, :string
    field :term_theme_name, :string
    field :term_theme_prefer_original, :boolean, default: true
    field :term_font_family, :string
    field :streaming_enabled, :boolean, default: true
    field :stream_recording_enabled, :boolean, default: true
    field :default_recording_visibility, Ecto.Enum, values: ~w[private unlisted public]a
    field :default_stream_visibility, Ecto.Enum, values: ~w[private unlisted public]a
    field :stream_limit, :integer
    field :last_login_at, :utc_datetime_usec
    field :is_admin, :boolean

    timestamps()

    has_many :asciicasts, Asciinema.Recordings.Asciicast
    has_many :streams, Asciinema.Streaming.Stream
    has_many :clis, Asciinema.Accounts.Cli
  end
end
