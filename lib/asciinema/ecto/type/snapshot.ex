defmodule Asciinema.Ecto.Type.Snapshot do
  use Ecto.Type
  alias Asciinema.Recordings.Snapshot

  def type, do: :text

  def cast(%Snapshot{} = value), do: {:ok, value}
  def cast(value) when is_list(value), do: {:ok, Snapshot.new(value)}
  def cast({lines, _} = value) when is_list(lines), do: {:ok, Snapshot.new(value)}

  def load(value) do
    snapshot =
      value
      |> Jason.decode!()
      |> Snapshot.new()

    {:ok, snapshot}
  end

  def dump(%Snapshot{} = value) do
    value
    |> Snapshot.unwrap()
    |> Jason.encode()
  end
end
