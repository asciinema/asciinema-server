defmodule Asciinema.Asciicast do
  use Asciinema.Web, :model
  alias Asciinema.{User, Asciicast}
  alias Asciinema.PngGenerator.PngParams

  @default_png_scale 2
  @default_theme "asciinema"

  schema "asciicasts" do
    field :version, :integer
    field :file, :string
    field :stdout_data, :string
    field :stdout_timing, :string
    field :stdout_frames, :string
    field :private, :boolean
    field :secret_token, :string
    field :duration, :float
    field :theme_name, :string
    field :snapshot_at, :float

    belongs_to :user, User
  end

  def by_id_or_secret_token(thing) do
    if String.length(thing) == 25 do
      from a in __MODULE__, where: a.secret_token == ^thing
    else
      case Integer.parse(thing) do
        {id, ""} ->
          from a in __MODULE__, where: a.private == false and a.id == ^id
        :error ->
          from a in __MODULE__, where: a.id == -1 # TODO fixme
      end
    end
  end

  def json_store_path(%__MODULE__{id: id, file: file}) when is_binary(file) do
    "asciicast/file/#{id}/#{file}"
  end
  def json_store_path(%__MODULE__{id: id, stdout_frames: stdout_frames}) when is_binary(stdout_frames) do
    "asciicast/stdout_frames/#{id}/#{stdout_frames}"
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
