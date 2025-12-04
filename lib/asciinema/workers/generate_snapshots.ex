defmodule Asciinema.Workers.GenerateSnapshots do
  use Oban.Worker,
    unique: [period: :infinity, states: :incomplete]

  alias Asciinema.Recordings
  alias Asciinema.Workers.UpdateSnapshot

  @impl Oban.Worker
  def perform(_job) do
    asciicasts =
      :snapshotless
      |> Recordings.query()
      |> Recordings.stream()

    Enum.each(asciicasts, fn asciicast ->
      Oban.insert!(UpdateSnapshot.new(%{asciicast_id: asciicast.id}))
    end)

    :ok
  end
end
