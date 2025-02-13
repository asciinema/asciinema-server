defmodule Asciinema.Workers.MarkOfflineStreams do
  use Oban.Worker,
    unique: [
      period: :infinity,
      states: [:scheduled, :available, :executing, :retryable]
    ]

  alias Asciinema.Streaming
  require Logger

  @impl Oban.Worker
  def perform(_job) do
    count = Streaming.mark_inactive_streams_offline()

    if count > 0 do
      Logger.info("marked #{count} streams offline")
    end

    :ok
  end
end
