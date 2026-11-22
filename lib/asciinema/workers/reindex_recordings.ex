defmodule Asciinema.Workers.ReindexRecordings do
  use Oban.Worker,
    unique: [period: :infinity, states: :incomplete]

  alias Asciinema.Recordings
  alias Asciinema.Recordings.Query, as: RecordingQuery
  alias Asciinema.Workers.UpdateFtsContent

  @impl Oban.Worker
  def perform(_job) do
    %RecordingQuery{scope: :system}
    |> Recordings.stream_ids()
    |> Enum.each(fn id ->
      Oban.insert!(UpdateFtsContent.new(%{asciicast_id: id}))
    end)

    :ok
  end
end
