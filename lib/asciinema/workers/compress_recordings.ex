defmodule Asciinema.Workers.CompressRecordings do
  use Oban.Worker,
    queue: :maintenance,
    unique: [period: :infinity, states: :incomplete]

  alias Asciinema.Recordings
  alias Asciinema.Workers.CompressRecording

  @impl Oban.Worker
  def perform(_job) do
    Enum.each(Recordings.uncompressed_asciicast_ids_stream(), fn id ->
      Oban.insert!(CompressRecording.new(%{asciicast_id: id}))
    end)

    :ok
  end
end
