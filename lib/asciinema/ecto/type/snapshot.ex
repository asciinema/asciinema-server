defmodule Asciinema.Ecto.Type.Snapshot do
  use Ecto.Type
  alias Asciinema.Recordings.Snapshot

  def type, do: :text

  def cast({lines, _} = value) when is_list(lines), do: {:ok, Snapshot.build(value, :segments)}

  def load(value) do
    snapshot =
      value
      |> Jason.decode!()
      |> Snapshot.new(:segments)

    {:ok, snapshot}
  end

  def dump(%Snapshot{} = value) do
    lines =
      for segments <- Snapshot.to_segments(value) do
        for segment <- segments do
          Tuple.to_list(segment)
        end
      end

    Jason.encode(lines)
  end
end
