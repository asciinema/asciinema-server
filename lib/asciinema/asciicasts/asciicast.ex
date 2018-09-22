defmodule Asciinema.Asciicasts.Asciicast do
  use Ecto.Schema
  import Ecto.Changeset
  alias Asciinema.Accounts.User
  alias Asciinema.Asciicasts.Asciicast
  alias Asciinema.PngGenerator.PngParams

  @default_png_scale 2
  @default_theme "asciinema"

  schema "asciicasts" do
    field :version, :integer
    field :file, :string
    field :terminal_columns, :integer
    field :terminal_lines, :integer
    field :terminal_type, :string
    field :stdout_data, :string
    field :stdout_timing, :string
    field :stdout_frames, :string
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
    field :recorded_at, Timex.Ecto.DateTime
    field :idle_time_limit, :float

    timestamps(inserted_at: :created_at)

    belongs_to :user, User
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
    |> cast(attrs, [:version, :file, :duration, :terminal_columns, :terminal_lines, :terminal_type, :command, :shell, :uname, :user_agent, :recorded_at, :theme_fg, :theme_bg, :theme_palette, :idle_time_limit])
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

  def json_store_path(%Asciicast{file: v} = asciicast) when is_binary(v) do
    file_store_path(asciicast, :file)
  end

  def json_store_path(%Asciicast{stdout_frames: v} = asciicast) when is_binary(v) do
    file_store_path(asciicast, :stdout_frames)
  end

  def file_store_path(%Asciicast{id: id, file: fname}, :file) do
    file_store_path(:file, id, fname)
  end

  def file_store_path(%Asciicast{id: id, stdout_frames: fname}, :stdout_frames) do
    file_store_path(:stdout_frames, id, fname)
  end

  def file_store_path(%Asciicast{id: id, stdout_data: fname}, :stdout_data) do
    file_store_path(:stdout, id, fname)
  end

  def file_store_path(%Asciicast{id: id, stdout_timing: fname}, :stdout_timing) do
    file_store_path(:stdout_timing, id, fname)
  end

  def file_store_path(type, id, fname) when is_binary(fname) do
    "asciicast/#{type}/#{id}/#{fname}"
  end

  def file_store_path(_type, _id, _fname) do
    nil
  end

  def snapshot_at(%Asciicast{snapshot_at: snapshot_at, duration: duration}) do
    snapshot_at || duration / 2
  end

  def theme_name(%Asciicast{theme_name: a_theme_name}, %User{theme_name: u_theme_name}) do
    a_theme_name || u_theme_name || @default_theme
  end

  def png_params(%Asciicast{} = asciicast, %User{} = user) do
    %PngParams{snapshot_at: snapshot_at(asciicast),
               theme: theme_name(asciicast, user),
               scale: @default_png_scale}
  end
end
