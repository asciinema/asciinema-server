defmodule Asciinema.Asciicasts.Asciicast do
  use Ecto.Schema
  import Ecto.Changeset
  alias Asciinema.Accounts.User
  alias Asciinema.Asciicasts.Asciicast

  @default_theme "asciinema"

  @timestamps_opts [type: :utc_datetime_usec]

  schema "asciicasts" do
    field :version, :integer
    field :filename, :string
    field :path, :string
    field :terminal_columns, :integer
    field :terminal_lines, :integer
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
    field :views_count, :integer, default: 0
    field :archivable, :boolean, default: true
    field :archived_at, :utc_datetime_usec

    timestamps(inserted_at: :created_at)

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
      :terminal_columns,
      :terminal_lines,
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
    |> validate_required([:user_id, :version, :duration, :terminal_columns, :terminal_lines])
    |> generate_secret_token
  end

  def update_changeset(struct, attrs) do
    struct
    |> changeset(attrs)
    |> cast(attrs, [:description, :theme_name])
  end

  def snapshot_changeset(struct, snapshot) do
    cast(struct, %{snapshot: snapshot}, [:snapshot])
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
