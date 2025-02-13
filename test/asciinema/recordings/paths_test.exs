defmodule Asciinema.Recordings.PathsTest do
  use Asciinema.DataCase
  import Asciinema.Factory
  alias Asciinema.Recordings.Paths

  setup do
    on_exit_restore_config(Paths)

    :ok
  end

  describe "path/1" do
    test "returns path with json ext for asciicast v1" do
      now = Timex.now()
      asciicast = build_asciicast(version: 1, inserted_at: now)

      path = Paths.path(asciicast)

      assert path == "recordings/foo/#{now.year}/#{now.month}/#{now.day}/123.json"
    end

    test "returns path with cast ext for asciicast v2" do
      now = Timex.now()
      asciicast = build_asciicast(version: 2, inserted_at: now)

      path = Paths.path(asciicast)

      assert path == "recordings/foo/#{now.year}/#{now.month}/#{now.day}/123.cast"
    end

    test "uses last 4 digits (reversed) for {shard} token - short id" do
      Application.put_env(:asciinema, Paths, recording: "asciicasts/{shard}/{id}.{ext}")
      asciicast = build_asciicast(id: 1)

      path = Paths.path(asciicast)

      assert path == "asciicasts/10/00/1.cast"
    end

    test "uses last 4 digits (reversed) for {shard} token - long id" do
      Application.put_env(:asciinema, Paths, recording: "asciicasts/{shard}/{id}.{ext}")
      asciicast = build_asciicast(id: 12345)

      path = Paths.path(asciicast)

      assert path == "asciicasts/54/32/12345.cast"
    end
  end

  describe "path/2" do
    test "returns paths with overriden ext" do
      now = Timex.now()
      asciicast = build_asciicast(inserted_at: now)

      path = Paths.path(asciicast, "txt")

      assert path == "recordings/foo/#{now.year}/#{now.month}/#{now.day}/123.txt"
    end
  end

  defp build_asciicast(overrides) do
    attrs =
      Keyword.merge(
        [id: 123, version: 2, inserted_at: Timex.now(), user: build(:user, username: "foo")],
        overrides
      )

    build(:asciicast, attrs)
  end
end
