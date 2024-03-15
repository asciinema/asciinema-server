defmodule Asciinema.Streaming.LiveStream do
  use Ecto.Schema

  schema "live_streams" do
    field :secret_token, :string
    field :producer_token, :string
    field :private, :boolean, default: true
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
    field :terminal_line_height, :float
    field :terminal_font_family, :string
    field :current_viewer_count, :integer
    field :peak_viewer_count, :integer
    field :buffer_time, :float
    field :parser, :string

    timestamps()

    belongs_to :user, Asciinema.Accounts.User
  end

  defimpl Phoenix.Param do
    def to_param(%{private: true, secret_token: secret_token}) do
      secret_token
    end

    def to_param(%{id: id}) do
      Integer.to_string(id)
    end
  end
end
