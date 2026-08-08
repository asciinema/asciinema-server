defmodule Asciinema.Workers.UpdateFtsContentTest do
  use Asciinema.DataCase, async: true
  use Oban.Testing, repo: Asciinema.Repo

  import Asciinema.Factory

  alias Asciinema.Recordings
  alias Asciinema.Recordings.Query
  alias Asciinema.Workers.UpdateFtsContent

  describe "perform/1" do
    test "makes the recording content searchable" do
      asciicast = insert(:asciicast_v3) |> with_file()

      assert perform_job(UpdateFtsContent, %{asciicast_id: asciicast.id}) == :ok

      results =
        %Query{scope: :system, filters: [{:full_text, {:search, "foo"}}]}
        |> Recordings.list(10)

      assert Enum.map(results, & &1.id) == [asciicast.id]
    end

    test "discards the job when the recording is gone" do
      assert perform_job(UpdateFtsContent, %{asciicast_id: -1}) == :discard
    end
  end
end
