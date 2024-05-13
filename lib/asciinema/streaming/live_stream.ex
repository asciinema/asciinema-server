defmodule Asciinema.Streaming.LiveStream do
  use Ecto.Schema

  schema "live_streams" do
    field :public_token, :string
    field :producer_token, :string
    field :visibility, Ecto.Enum, values: [:private, :unlisted, :public], default: :unlisted
    field :cols, :integer
    field :rows, :integer
    field :online, :boolean
    field :last_activity_at, :naive_datetime
    field :last_started_at, :naive_datetime
    field :title, :string
    field :description, :string
    field :theme_name, :string
    field :theme_fg, :string
    field :theme_bg, :string
    field :theme_palette, :string
    field :theme_prefer_original, :boolean, default: true
    field :terminal_line_height, :float
    field :terminal_font_family, :string
    field :current_viewer_count, :integer
    field :peak_viewer_count, :integer
    field :buffer_time, :float
    field :parser, :string
    field :snapshot, Asciinema.Ecto.Type.JsonArray

    timestamps()

    belongs_to :user, Asciinema.Accounts.User
  end

  defimpl Phoenix.Param do
    def to_param(stream), do: stream.public_token
  end
end
