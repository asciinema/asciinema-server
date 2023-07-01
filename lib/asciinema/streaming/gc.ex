defmodule Asciinema.Streaming.GC do
  use Oban.Worker
  alias Asciinema.Streaming
  require Logger

  @impl Oban.Worker
  def perform(_job) do
    count = Streaming.mark_inactive_live_streams_offline()

    if count > 0 do
      Logger.info("marked #{count} streams offline")
    end

    :ok
  end
end
