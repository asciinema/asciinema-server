defmodule Asciinema.Workers.MarkOfflineStreams do
  use Oban.Worker,
    unique: [period: :infinity, states: :incomplete]

  alias Asciinema.Streaming
  require Logger

  @impl Oban.Worker
  def perform(_job) do
    if vm_uptime_sec() >= grace_period() do
      count = Streaming.mark_inactive_streams_offline()

      if count > 0 do
        Logger.info("marked #{count} streams offline")
      end
    end

    :ok
  end

  defp vm_uptime_sec do
    {total_ms, _} = :erlang.statistics(:wall_clock)

    total_ms / 1_000
  end

  @five_minutes_in_sec 5 * 60

  defp grace_period do
    Keyword.get(
      Application.get_env(:asciinema, __MODULE__, []),
      :grace_period,
      @five_minutes_in_sec
    )
  end
end
