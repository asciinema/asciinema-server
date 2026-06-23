defmodule Asciinema.Workers.CreateStreamRecordingTest do
  use Asciinema.DataCase, async: true
  use Oban.Testing, repo: Asciinema.Repo

  import Asciinema.Factory
  import Ecto.Query

  alias Asciinema.FileStore
  alias Asciinema.Recordings.Asciicast
  alias Asciinema.Workers.CreateStreamRecording

  @cast_fixture "test/fixtures/3/full.cast"
  @empty_cast_fixture "test/fixtures/3/no-events.cast"

  describe "perform/1" do
    test "creates a recording from a staged capture and deletes the staged file" do
      user = insert(:user)
      stream = insert(:stream, user: user)
      staging_path = stage_cast(stream.id)

      args = %{
        "user_id" => user.id,
        "stream_id" => stream.id,
        "file_store_path" => staging_path,
        "user_agent" => "test/agent",
        "term_bold_is_bright" => true,
        "term_adaptive_palette" => false,
        "keystroke_overlay" => true,
        "term_cursor_mode" => "hidden"
      }

      assert :ok = perform_job(CreateStreamRecording, args)

      assert [
               %Asciicast{
                 stream_id: stream_id,
                 user_agent: "test/agent",
                 term_bold_is_bright: true,
                 term_adaptive_palette: false,
                 keystroke_overlay: true,
                 term_cursor_mode: "hidden",
                 filename: "stream.cast"
               } = asciicast
             ] = asciicasts_for(user)

      assert stream_id == stream.id
      refute asciicast.archived_at
      refute file_in_store?(staging_path)
    end

    test "retries with stream_id: nil when stream is missing" do
      user = insert(:user)
      missing_stream_id = 999_999_999
      staging_path = stage_cast(missing_stream_id)

      args = %{
        "user_id" => user.id,
        "stream_id" => missing_stream_id,
        "file_store_path" => staging_path,
        "user_agent" => "test/agent",
        "term_bold_is_bright" => false,
        "term_adaptive_palette" => false,
        "keystroke_overlay" => false,
        "term_cursor_mode" => "blinking"
      }

      assert :ok = perform_job(CreateStreamRecording, args)

      assert [%Asciicast{stream_id: nil}] = asciicasts_for(user)
      refute file_in_store?(staging_path)
    end

    test "discards when user no longer exists and keeps the staged file" do
      stream = insert(:stream)
      staging_path = stage_cast(stream.id)

      args = %{
        "user_id" => 999_999_999,
        "stream_id" => stream.id,
        "file_store_path" => staging_path,
        "user_agent" => nil,
        "term_bold_is_bright" => false,
        "term_adaptive_palette" => false
      }

      assert :discard = perform_job(CreateStreamRecording, args)
      assert file_in_store?(staging_path)
    end

    test "discards an empty staged capture and deletes the staged file" do
      user = insert(:user)
      stream = insert(:stream, user: user)
      staging_path = stage_cast(stream.id, @empty_cast_fixture)

      args = %{
        "user_id" => user.id,
        "stream_id" => stream.id,
        "file_store_path" => staging_path,
        "user_agent" => "test/agent",
        "term_bold_is_bright" => false,
        "term_adaptive_palette" => false,
        "keystroke_overlay" => false,
        "term_cursor_mode" => "blinking"
      }

      assert :discard = perform_job(CreateStreamRecording, args)
      assert [] = asciicasts_for(user)
      refute file_in_store?(staging_path)
    end
  end

  defp asciicasts_for(user) do
    Repo.all(from a in Asciicast, where: a.user_id == ^user.id)
  end

  defp stage_cast(stream_id, fixture \\ @cast_fixture) do
    path = "tmp/stream-recordings/test/#{stream_id}-#{System.unique_integer([:positive])}.cast"
    :ok = FileStore.put_file(path, fixture, "application/x-asciicast")
    path
  end

  defp file_in_store?(path) do
    "file://" <> abs_path = FileStore.uri(path)
    File.exists?(abs_path)
  end
end
