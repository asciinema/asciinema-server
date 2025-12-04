defmodule Asciinema.Workers.RescheduleStreams do
  use Oban.Worker,
    unique: [period: :infinity, states: :incomplete]

  alias Asciinema.Streaming

  @impl Oban.Worker
  def perform(_job) do
    Streaming.reschedule_streams()
  end
end
