defmodule Asciinema.Streaming.LiveStream do
  use Ecto.Schema

  schema "live_streams" do
    field :producer_token, :string
    field :cols, :integer
    field :rows, :integer
    field :online, :boolean
    field :last_activity_at, :naive_datetime

    timestamps()

    belongs_to :user, Asciinema.Accounts.User
  end
end
