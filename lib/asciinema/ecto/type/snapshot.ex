defmodule Asciinema.Ecto.Type.Snapshot do
  use Ecto.Type
  alias Asciinema.Recordings.Snapshot

  def type, do: :text

  def cast({rows, cursor}) when is_list(rows) do
    {:ok, Snapshot.from_segments(rows, cursor)}
  end

  def load(value) do
    case Jason.decode!(value) do
      %{"rows" => rows, "cursor" => cursor} ->
        cursor = if cursor, do: List.to_tuple(cursor)
        {:ok, Snapshot.from_segments(rows, cursor)}

      rows when is_list(rows) ->
        {:ok, Snapshot.from_segments(rows)}
    end
  end

  def dump(%Snapshot{} = snapshot) do
    cursor = if snapshot.cursor, do: Tuple.to_list(snapshot.cursor)
    Jason.encode(%{rows: Snapshot.to_segments(snapshot), cursor: cursor})
  end
end
