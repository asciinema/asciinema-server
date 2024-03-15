defmodule Asciinema.Recordings.Asciicast do
  use Ecto.Schema
  alias Asciinema.Accounts.User
  alias Asciinema.Recordings.Asciicast

  @default_theme "asciinema"

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
    field :private, :boolean
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

    belongs_to :user, User

    # legacy
    field :stdout_data, :string
    field :stdout_timing, :string
  end

  defimpl Phoenix.Param, for: Asciicast do
    def to_param(%Asciicast{private: true, secret_token: secret_token}) do
      secret_token
    end

    def to_param(%Asciicast{id: id}) do
      Integer.to_string(id)
    end
  end

  def snapshot_at(%Asciicast{snapshot_at: snapshot_at, duration: duration}) do
    snapshot_at || duration / 2
  end

  def theme_name(%Asciicast{theme_name: a_theme_name}, %User{theme_name: u_theme_name}) do
    a_theme_name || u_theme_name || @default_theme
  end
end
