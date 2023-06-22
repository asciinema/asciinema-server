defmodule Asciinema.Streaming.LiveStream do
  use Ecto.Schema

  schema "live_streams" do
    field :producer_token, :string
    timestamps()
    belongs_to :user, Asciinema.Accounts.User
  end
end
