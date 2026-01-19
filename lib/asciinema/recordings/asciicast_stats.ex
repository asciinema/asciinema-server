defmodule Asciinema.Recordings.AsciicastStats do
  use Ecto.Schema
  alias Asciinema.Recordings.Asciicast

  @primary_key {:asciicast_id, :id, autogenerate: false}
  schema "asciicast_stats" do
    field :total_views, :integer
    field :popularity_score, :float
    field :popularity_dirty, :boolean

    belongs_to :asciicast, Asciicast, define_field: false
  end
end
