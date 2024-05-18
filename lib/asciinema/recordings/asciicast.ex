defmodule Asciinema.Recordings.Asciicast do
  use Ecto.Schema
  alias __MODULE__

  @timestamps_opts [type: :utc_datetime_usec]

  schema "asciicasts" do
    field :version, :integer
    field :filename, :string
    field :path, :string
    field :cols, :integer
    field :cols_override, :integer
    field :rows, :integer
    field :rows_override, :integer
    field :terminal_type, :string
    field :visibility, Ecto.Enum, values: [:private, :unlisted, :public], default: :unlisted
    field :featured, :boolean
    field :secret_token, :string
    field :duration, :float
    field :title, :string
    field :description, :string
    field :theme_name, :string
    field :theme_fg, :string
    field :theme_bg, :string
    field :theme_palette, :string
    field :snapshot_at, :float
    field :snapshot, Asciinema.Ecto.Type.JsonArray
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
    field :terminal_line_height, :float
    field :terminal_font_family, :string
    field :markers, :string

    timestamps()

    belongs_to :user, Asciinema.Accounts.User

    # legacy
    field :stdout_data, :string
    field :stdout_timing, :string
  end

  defimpl Phoenix.Param do
    def to_param(%Asciicast{visibility: :public} = asciicast), do: Integer.to_string(asciicast.id)
    def to_param(%Asciicast{} = asciicast), do: asciicast.secret_token
  end
end
