defmodule Asciinema.Recordings.Asciicast do
  use Ecto.Schema
  alias __MODULE__

  @timestamps_opts [type: :utc_datetime_usec]

  schema "asciicasts" do
    field :version, :integer
    field :filename, :string
    field :path, :string
    field :term_cols, :integer
    field :term_cols_override, :integer
    field :term_rows, :integer
    field :term_rows_override, :integer
    field :term_type, :string
    field :term_version, :string
    field :term_theme_name, :string
    field :term_theme_fg, :string
    field :term_theme_bg, :string
    field :term_theme_palette, :string
    field :term_line_height, :float
    field :term_font_family, :string
    field :visibility, Ecto.Enum, values: ~w[private unlisted public]a, default: :unlisted
    field :featured, :boolean
    field :secret_token, :string
    field :duration, :float
    field :title, :string
    field :description, :string
    field :snapshot_at, :float
    field :snapshot, Asciinema.Ecto.Type.Snapshot
    field :command, :string
    field :shell, :string
    field :uname, :string
    field :user_agent, :string
    field :recorded_at, :utc_datetime_usec
    field :idle_time_limit, :float
    field :speed, :float
    field :views_count, :integer, default: 0
    field :archivable, :boolean, default: true
    field :archived_at, :utc_datetime_usec
    field :markers, :string
    field :env, :map
    field :audio_url, :string

    timestamps()

    belongs_to :user, Asciinema.Accounts.User
    belongs_to :cli, Asciinema.Accounts.Cli
    belongs_to :stream, Asciinema.Streaming.Stream
  end

  defimpl Phoenix.Param do
    def to_param(%Asciicast{visibility: :public} = asciicast), do: Integer.to_string(asciicast.id)
    def to_param(%Asciicast{} = asciicast), do: asciicast.secret_token
  end
end
