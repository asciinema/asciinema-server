defmodule Asciinema.Workers.CompressRecordingTest do
  use Asciinema.DataCase, async: true
  use Oban.Testing, repo: Asciinema.Repo

  import Asciinema.Factory

  alias Asciinema.Recordings
  alias Asciinema.Workers.CompressRecording

  describe "perform/1" do
    test "compresses the recording file" do
      asciicast = insert(:asciicast_v2, compressed: false) |> with_file()

      assert perform_job(CompressRecording, %{asciicast_id: asciicast.id}) == :ok

      assert Recordings.get_asciicast(asciicast.id).compressed
    end

    test "discards the job when the recording is gone" do
      assert perform_job(CompressRecording, %{asciicast_id: -1}) == :discard
    end
  end
end
