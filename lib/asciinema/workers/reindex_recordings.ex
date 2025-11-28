defmodule Asciinema.Workers.ReindexRecordings do
  use Oban.Worker,
    unique: [period: :infinity, states: :incomplete]

  alias Asciinema.Recordings
  alias Asciinema.Workers.UpdateFtsContent

  @impl Oban.Worker
  def perform(_job) do
    asciicasts = Recordings.stream(Recordings.query())

    Enum.each(asciicasts, fn asciicast ->
      Oban.insert!(UpdateFtsContent.new(%{asciicast_id: asciicast.id}))
    end)

    :ok
  end
end
