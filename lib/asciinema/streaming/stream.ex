defmodule Asciinema.Streaming.Stream do
  use Ecto.Schema

  schema "streams" do
    field :public_token, :string
    field :producer_token, :string
    field :visibility, Ecto.Enum, values: ~w[private unlisted public]a, default: :unlisted
    field :term_cols, :integer
    field :term_rows, :integer
    field :term_theme_name, :string
    field :term_theme_fg, :string
    field :term_theme_bg, :string
    field :term_theme_palette, :string
    field :term_theme_prefer_original, :boolean, default: true
    field :term_line_height, :float
    field :term_font_family, :string
    field :online, :boolean
    field :last_activity_at, :naive_datetime
    field :last_started_at, :naive_datetime
    field :title, :string
    field :description, :string
    field :current_viewer_count, :integer
    field :peak_viewer_count, :integer
    field :buffer_time, :float
    field :protocol, :string
    field :snapshot, Asciinema.Ecto.Type.Snapshot

    timestamps()

    belongs_to :user, Asciinema.Accounts.User
  end

  defimpl Phoenix.Param do
    def to_param(stream), do: stream.public_token
  end
end
