defmodule Asciinema.Streaming.ViewerTracker do
  use Phoenix.Tracker
  alias Asciinema.PubSub
  alias Phoenix.Tracker
  require Logger

  defmodule Update do
    defstruct [:stream_id, :viewer_count]
  end

  # Public API

  def start_link(opts) do
    opts = Keyword.merge([name: __MODULE__], opts)
    Tracker.start_link(__MODULE__, opts, opts)
  end

  def count(stream_id) do
    length(Tracker.list(__MODULE__, stream_id))
  end

  def track(stream_id) do
    Tracker.track(__MODULE__, self(), stream_id, "", %{})
  end

  def untrack(stream_id) do
    Tracker.untrack(__MODULE__, self(), stream_id, "")
  end

  def subscribe(stream_id) do
    PubSub.subscribe(topic_name(stream_id))
  end

  # Callbacks

  @impl true
  def init(opts) do
    server = Keyword.fetch!(opts, :pubsub_server)
    {:ok, %{counts: %{}, pubsub_server: server}}
  end

  @impl true
  def handle_diff(diff, state) do
    counts =
      Enum.reduce(diff, %{}, fn {stream_id, {joins, leaves}}, counts ->
        delta = length(joins) - length(leaves)

        if delta == 0 do
          counts
        else
          Map.update(counts, stream_id, delta, fn c -> c + delta end)
        end
      end)

    send(self(), {:publish, Map.keys(counts)})

    counts = Map.merge(state.counts, counts, fn _k, c1, c2 -> c1 + c2 end)

    {:ok, %{state | counts: counts}}
  end

  @impl true
  def handle_info({:publish, stream_ids}, state) do
    for stream_id <- stream_ids do
      count = Map.get(state.counts, stream_id, 0)
      Logger.debug("tracker/#{stream_id}: viewer count: #{count}")
      PubSub.broadcast(topic_name(stream_id), %Update{stream_id: stream_id, viewer_count: count})
    end

    {:noreply, state}
  end

  # Private

  defp topic_name(stream_id), do: "stream:#{stream_id}:viewers"
end
