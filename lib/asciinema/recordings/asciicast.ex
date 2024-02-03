defmodule Asciinema.Recordings.Asciicast do
  use Ecto.Schema
  import Ecto.Changeset
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

  defp changeset(struct, attrs) do
    struct
    |> cast(attrs, [:title, :private, :snapshot_at])
    |> validate_required([:private])
  end

  def create_changeset(struct, attrs) do
    struct
    |> changeset(attrs)
    |> cast(attrs, [
      :version,
      :duration,
      :cols,
      :rows,
      :terminal_type,
      :command,
      :shell,
      :uname,
      :user_agent,
      :recorded_at,
      :theme_fg,
      :theme_bg,
      :theme_palette,
      :idle_time_limit,
      :snapshot
    ])
    |> validate_required([:user_id, :version, :duration, :cols, :rows])
    |> generate_secret_token
  end

  def update_changeset(struct, attrs, custom_terminal_font_families \\ [], themes \\ []) do
    struct
    |> changeset(attrs)
    |> cast(attrs, [
      :description,
      :cols_override,
      :rows_override,
      :theme_name,
      :idle_time_limit,
      :speed,
      :terminal_line_height,
      :terminal_font_family,
      :markers
    ])
    |> validate_number(:cols_override, greater_than: 0, less_than: 1024)
    |> validate_number(:rows_override, greater_than: 0, less_than: 512)
    |> validate_number(:idle_time_limit, greater_than_or_equal_to: 0.5)
    |> validate_inclusion(:theme_name, themes)
    |> validate_number(:terminal_line_height,
      greater_than_or_equal_to: 1.0,
      less_than_or_equal_to: 2.0
    )
    |> validate_inclusion(:terminal_font_family, custom_terminal_font_families)
    |> validate_number(:snapshot_at, greater_than: 0)
    |> validate_change(:markers, &validate_markers/2)
  end

  defp validate_markers(_, markers) do
    case parse_markers(markers) do
      {:ok, _} -> []
      {:error, index} -> [markers: "invalid syntax in line #{index + 1}"]
    end
  end

  def parse_markers(markers) do
    results =
      markers
      |> String.trim()
      |> String.split("\n")
      |> Enum.map(&parse_marker/1)

    case Enum.find_index(results, fn result -> result == :error end) do
      nil -> {:ok, results}
      index -> {:error, index}
    end
  end

  defp parse_marker(marker) do
    parts =
      marker
      |> String.trim()
      |> String.split(~r/\s+-\s+/, parts: 2)
      |> Kernel.++([""])
      |> Enum.take(2)

    with [t, l] <- parts,
         {t, ""} <- Float.parse(t),
         true <- String.length(l) < 100 do
      {t, l}
    else
      _ -> :error
    end
  end

  defp generate_secret_token(changeset) do
    put_change(changeset, :secret_token, Crypto.random_token(25))
  end

  def snapshot_at(%Asciicast{snapshot_at: snapshot_at, duration: duration}) do
    snapshot_at || duration / 2
  end

  def theme_name(%Asciicast{theme_name: a_theme_name}, %User{theme_name: u_theme_name}) do
    a_theme_name || u_theme_name || @default_theme
  end
end
