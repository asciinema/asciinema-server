defmodule Asciinema.Recordings.PathsTest do
  use Asciinema.DataCase, async: true
  import Asciinema.Factory
  alias Asciinema.AppEnv
  alias Asciinema.Recordings.Paths

  describe "path/1" do
    test "returns path with json ext for asciicast v1" do
      now = Timex.now()
      date = Timex.format!(now, "{YYYY}/{0M}/{0D}")
      asciicast = build_asciicast(version: 1, inserted_at: now)

      path = Paths.path(asciicast)

      assert path == "recordings/foo/#{date}/123.json"
    end

    test "returns path with cast ext for asciicast v2" do
      now = Timex.now()
      date = Timex.format!(now, "{YYYY}/{0M}/{0D}")
      asciicast = build_asciicast(version: 2, inserted_at: now)

      path = Paths.path(asciicast)

      assert path == "recordings/foo/#{date}/123.cast"
    end

    test "uses last 4 digits (reversed) for {shard} token - short id" do
      AppEnv.put(Paths, recording: "asciicasts/{shard}/{id}.{ext}")
      asciicast = build_asciicast(id: 1)

      path = Paths.path(asciicast)

      assert path == "asciicasts/10/00/1.cast"
    end

    test "uses last 4 digits (reversed) for {shard} token - long id" do
      AppEnv.put(Paths, recording: "asciicasts/{shard}/{id}.{ext}")
      asciicast = build_asciicast(id: 12345)

      path = Paths.path(asciicast)

      assert path == "asciicasts/54/32/12345.cast"
    end

    test "interpolates env vars" do
      AppEnv.put(Paths,
        recording: "recordings/{env:A_YES}-{env:A_NOPE?nope}-{env:NADA?}/{id}.{ext}"
      )

      asciicast = build_asciicast(env: %{"A_YES" => "yes"})

      path = Paths.path(asciicast)

      assert path == "recordings/yes-nope-/123.cast"
    end
  end

  describe "path/2" do
    test "returns paths with overriden ext" do
      now = Timex.now()
      date = Timex.format!(now, "{YYYY}/{0M}/{0D}")
      asciicast = build_asciicast(inserted_at: now)

      path = Paths.path(asciicast, "txt")

      assert path == "recordings/foo/#{date}/123.txt"
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
