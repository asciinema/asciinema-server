defmodule Asciinema.Workers.UpdateSnapshot do
  use Oban.Worker,
    unique: [
      period: :infinity,
      states: [:available, :retryable]
    ]

  alias Asciinema.Recordings

  @impl Oban.Worker
  def perform(job) do
    if asciicast = Recordings.get_asciicast(job.args["asciicast_id"]) do
      Recordings.update_snapshot(asciicast)
    else
      :discard
    end
  end
end
