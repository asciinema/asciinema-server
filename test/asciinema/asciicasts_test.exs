defmodule Asciinema.AsciicastsTest do
  use Asciinema.DataCase
  import Asciinema.Factory
  alias Asciinema.Asciicasts
  alias Asciinema.Asciicasts.Asciicast

  describe "create_asciicast/3" do
    test "pre-v1 payload with uname" do
      user = fixture(:user)

      params = %{
        "meta" => %{
          "version" => 0,
          "command" => "/bin/bash",
          "duration" => 11.146430015564,
          "shell" => "/bin/zsh",
          "term" => %{"columns" => 96, "lines" => 26, "type" => "screen-256color"},
          "title" => "bashing :)",
          "uname" => "Linux 3.9.9-302.fc19.x86_64 #1 SMP Sat Jul 6 13:41:07 UTC 2013 x86_64"
        },
        "stdout" =>
          fixture(:upload, %{path: "0.9.7/stdout", content_type: "application/octet-stream"}),
        "stdout_timing" =>
          fixture(:upload, %{path: "0.9.7/stdout.time", content_type: "application/octet-stream"})
      }

      {:ok, asciicast} = Asciicasts.create_asciicast(user, params, %{user_agent: "a/user/agent"})

      assert %Asciicast{
               version: 2,
               command: "/bin/bash",
               duration: 3.7037009999999997,
               shell: "/bin/zsh",
               terminal_type: "screen-256color",
               terminal_columns: 96,
               terminal_lines: 26,
               title: "bashing :)",
               uname: "Linux 3.9.9-302.fc19.x86_64 #1 SMP Sat Jul 6 13:41:07 UTC 2013 x86_64",
               user_agent: nil
             } = asciicast

      assert asciicast.path =~ ~r|\d\d/\d\d/#{asciicast.id}\.cast$|
    end

    test "pre-v1 payload without uname" do
      user = fixture(:user)

      params = %{
        "meta" => %{
          "version" => 0,
          "command" => "/bin/bash",
          "duration" => 11.146430015564,
          "shell" => "/bin/zsh",
          "term" => %{"columns" => 96, "lines" => 26, "type" => "screen-256color"},
          "title" => "bashing :)"
        },
        "stdout" =>
          fixture(:upload, %{path: "0.9.8/stdout", content_type: "application/octet-stream"}),
        "stdout_timing" =>
          fixture(:upload, %{path: "0.9.8/stdout.time", content_type: "application/octet-stream"})
      }

      {:ok, asciicast} = Asciicasts.create_asciicast(user, params, %{user_agent: "a/user/agent"})

      assert %Asciicast{
               version: 2,
               command: "/bin/bash",
               duration: 3.7037009999999997,
               shell: "/bin/zsh",
               terminal_type: "screen-256color",
               terminal_columns: 96,
               terminal_lines: 26,
               title: "bashing :)",
               uname: nil,
               user_agent: "a/user/agent"
             } = asciicast

      assert asciicast.path =~ ~r|\d\d/\d\d/#{asciicast.id}\.cast$|
    end

    test "pre-v1 payload, utf-8 sequence split between frames" do
      user = fixture(:user)

      params = %{
        "meta" => %{
          "version" => 0,
          "command" => "/bin/bash",
          "duration" => 11.146430015564,
          "shell" => "/bin/zsh",
          "term" => %{"columns" => 96, "lines" => 26, "type" => "screen-256color"},
          "title" => "bashing :)"
        },
        "stdout" =>
          fixture(:upload, %{path: "0.9.8/stdout-split", content_type: "application/octet-stream"}),
        "stdout_timing" =>
          fixture(:upload, %{
            path: "0.9.8/stdout-split.time",
            content_type: "application/octet-stream"
          })
      }

      {:ok, asciicast} = Asciicasts.create_asciicast(user, params, %{user_agent: "a/user/agent"})
      stream = Asciicasts.stdout_stream(asciicast)

      assert :ok == Stream.run(stream)
      assert [{1.234567, "xxżó"}, {1.358023, "łć"}, {3.358023, "xx"}] == Enum.take(stream, 3)
    end

    test "json file, v1 format" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "1/asciicast.json"})

      {:ok, asciicast} = Asciicasts.create_asciicast(user, upload, %{user_agent: "a/user/agent"})

      assert %Asciicast{
               version: 1,
               command: "/bin/bash",
               duration: 11.146430015564,
               shell: "/bin/zsh",
               terminal_type: "screen-256color",
               terminal_columns: 96,
               terminal_lines: 26,
               title: "bashing :)",
               uname: nil,
               user_agent: "a/user/agent"
             } = asciicast

      assert asciicast.path =~ ~r|\d\d/\d\d/#{asciicast.id}\.json$|
    end

    test "json file, v1 format (missing required data)" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "1/invalid.json"})

      assert {:error, %Ecto.Changeset{}} = Asciicasts.create_asciicast(user, upload)
    end

    test "json file, unsupported version number" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "5/asciicast.json"})

      assert {:error, {:unsupported_format, 5}} = Asciicasts.create_asciicast(user, upload)
    end

    test "cast file, v2 format, minimal" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "2/minimal.cast"})

      {:ok, asciicast} = Asciicasts.create_asciicast(user, upload, %{user_agent: "a/user/agent"})

      assert %Asciicast{
               version: 2,
               terminal_columns: 96,
               terminal_lines: 26,
               duration: 8.456789,
               command: nil,
               recorded_at: nil,
               shell: nil,
               terminal_type: nil,
               title: nil,
               theme_fg: nil,
               theme_bg: nil,
               theme_palette: nil,
               idle_time_limit: nil,
               uname: nil,
               user_agent: "a/user/agent"
             } = asciicast

      assert asciicast.path =~ ~r|\d\d/\d\d/#{asciicast.id}\.cast$|
    end

    test "cast file, v2 format, full" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "2/full.cast"})

      {:ok, asciicast} = Asciicasts.create_asciicast(user, upload, %{user_agent: "a/user/agent"})

      assert %Asciicast{
               version: 2,
               terminal_columns: 96,
               terminal_lines: 26,
               duration: 6.234567,
               command: "/bin/bash -l",
               shell: "/bin/zsh",
               terminal_type: "screen-256color",
               title: "bashing :)",
               theme_fg: "#aaaaaa",
               theme_bg: "#bbbbbb",
               theme_palette:
                 "#151515:#ac4142:#7e8e50:#e5b567:#6c99bb:#9f4e85:#7dd6cf:#d0d0d0:#505050:#ac4142:#7e8e50:#e5b567:#6c99bb:#9f4e85:#7dd6cf:#f5f5f5",
               idle_time_limit: 2.5,
               uname: nil,
               user_agent: "a/user/agent"
             } = asciicast

      assert asciicast.path =~ ~r|\d\d/\d\d/#{asciicast.id}\.cast$|
      assert DateTime.to_unix(asciicast.recorded_at) == 1_506_410_422
    end

    test "unknown file format" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "new-logo-bars.png"})

      assert {:error, :unknown_format} = Asciicasts.create_asciicast(user, upload)
    end
  end

  describe "delete_asciicast/1" do
    test "v1/v2" do
      asciicast = insert(:asciicast_v1) |> with_file()
      assert {:ok, _asciicast} = Asciicasts.delete_asciicast(asciicast)

      asciicast = insert(:asciicast_v2) |> with_file()
      assert {:ok, _asciicast} = Asciicasts.delete_asciicast(asciicast)
    end
  end

  describe "stdout_stream/1" do
    test "with asciicast v1 file" do
      stream = Asciicasts.stdout_stream("test/fixtures/1/asciicast.json")
      assert :ok == Stream.run(stream)
      assert [{1.234567, "foo bar"}, {6.913554, "baz qux"}] == Enum.take(stream, 2)
    end

    test "with asciicast v2 file" do
      stream = Asciicasts.stdout_stream("test/fixtures/2/minimal.cast")
      assert :ok == Stream.run(stream)
      assert [{1.234567, "foo bar"}, {5.678987, "baz qux"}] == Enum.take(stream, 2)
    end

    test "with asciicast v2 file, with idle_time_limit" do
      stream = Asciicasts.stdout_stream("test/fixtures/2/full.cast")
      assert :ok == Stream.run(stream)

      assert [{1.234567, "foo bar"}, {3.734567, "baz qux"}, {6.234567, "żółć jaźń"}] ==
               Enum.take(stream, 3)
    end

    test "with asciicast v2 file, with blank lines" do
      stream = Asciicasts.stdout_stream("test/fixtures/2/with-blank-lines.cast")
      assert :ok == Stream.run(stream)

      assert [{1.234567, "foo bar"}, {5.678987, "baz qux"}, {8.456789, "żółć jaźń"}] ==
               Enum.to_list(stream)
    end
  end

  describe "stdout_stream/2" do
    test "with gzipped files" do
      stream =
        Asciicasts.stdout_stream(
          {"test/fixtures/0.9.9/stdout.time", "test/fixtures/0.9.9/stdout"}
        )

      assert :ok == Stream.run(stream)
      assert [{1.234567, "foobar"}, {1.358023, "baz"}] == Enum.take(stream, 2)
    end

    test "with bzipped files" do
      stream =
        Asciicasts.stdout_stream(
          {"test/fixtures/0.9.8/stdout.time", "test/fixtures/0.9.8/stdout"}
        )

      assert :ok == Stream.run(stream)
      assert [{1.234567, "foobar"}, {1.358023, "baz"}] == Enum.take(stream, 2)
    end

    test "with bzipped files (utf-8 sequence split between frames)" do
      stream =
        Asciicasts.stdout_stream(
          {"test/fixtures/0.9.8/stdout-split.time", "test/fixtures/0.9.8/stdout-split"}
        )

      assert :ok == Stream.run(stream)
      assert [{1.234567, "xxżó"}, {1.358023, "łć"}, {3.358023, "xx"}] == Enum.take(stream, 3)
    end
  end

  describe "generate_snapshot/2" do
    @tag :vt
    test "returns list of screen lines" do
      stdout_stream = [{1.0, "a"}, {2.4, "b"}, {2.6, "c"}]
      snapshot = Asciicasts.generate_snapshot(stdout_stream, 4, 2, 2.5)
      assert snapshot == [[["ab", %{}], [" ", %{"inverse" => true}], [" ", %{}]], [["    ", %{}]]]
    end
  end

  describe "upgrade/1" do
    test "keeps v1 and v2 intact" do
      asciicast_v1 = insert(:asciicast_v1)
      asciicast_v2 = insert(:asciicast_v2)

      assert ^asciicast_v1 = Asciicasts.upgrade(asciicast_v1)
      assert ^asciicast_v2 = Asciicasts.upgrade(asciicast_v2)
    end

    test "converts v0 file to v2" do
      asciicast = insert(:asciicast_v0) |> with_files()

      stream_v0 =
        asciicast
        |> Asciicasts.stdout_stream()
        |> Enum.to_list()

      asciicast = Asciicasts.upgrade(asciicast)
      assert asciicast.version == 2
      assert asciicast.path =~ ~r|\d\d/\d\d/#{asciicast.id}\.cast$|

      stream_v2 =
        asciicast
        |> Asciicasts.stdout_stream()
        |> Enum.to_list()

      assert stream_v0 == stream_v2
    end
  end
end
