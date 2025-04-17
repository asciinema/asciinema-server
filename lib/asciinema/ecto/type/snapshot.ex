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
    value
    |> Snapshot.regroup(:cells)
    |> Snapshot.regroup(:segments, split_specials: false)
    |> Snapshot.unwrap()
    |> Jason.encode()
  end
end
