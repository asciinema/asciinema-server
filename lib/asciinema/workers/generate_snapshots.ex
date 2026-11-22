defmodule Asciinema.Workers.GenerateSnapshots do
  use Oban.Worker,
    unique: [period: :infinity, states: :incomplete]

  alias Asciinema.Recordings
  alias Asciinema.Recordings.Query, as: RecordingQuery
  alias Asciinema.Workers.UpdateSnapshot

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    query =
      case args do
        %{"all" => true} -> %RecordingQuery{scope: :system, archived: :include}
        _ -> %RecordingQuery{scope: :system, filters: [:snapshotless]}
      end

    query
    |> Recordings.stream_ids()
    |> Enum.each(fn id ->
      Oban.insert!(UpdateSnapshot.new(%{asciicast_id: id}))
    end)

    :ok
  end
end
