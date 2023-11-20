defmodule Asciinema.RecordingsTest do
  use Asciinema.DataCase
  import Asciinema.Factory
  alias Asciinema.Recordings
  alias Asciinema.Recordings.Asciicast

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

      {:ok, asciicast} = Recordings.create_asciicast(user, params, %{user_agent: "a/user/agent"})

      assert %Asciicast{
               version: 2,
               command: "/bin/bash",
               duration: 3.7037009999999997,
               shell: "/bin/zsh",
               terminal_type: "screen-256color",
               cols: 96,
               rows: 26,
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

      {:ok, asciicast} = Recordings.create_asciicast(user, params, %{user_agent: "a/user/agent"})

      assert %Asciicast{
               version: 2,
               command: "/bin/bash",
               duration: 3.7037009999999997,
               shell: "/bin/zsh",
               terminal_type: "screen-256color",
               cols: 96,
               rows: 26,
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

      {:ok, asciicast} = Recordings.create_asciicast(user, params, %{user_agent: "a/user/agent"})
      stream = Recordings.Output.stream(asciicast)

      assert :ok == Stream.run(stream)
      assert [{1.234567, "xxżó"}, {1.358023, "łć"}, {3.358023, "xx"}] == Enum.take(stream, 3)
    end

    test "json file, v1 format" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "1/asciicast.json"})

      {:ok, asciicast} = Recordings.create_asciicast(user, upload, %{user_agent: "a/user/agent"})

      assert %Asciicast{
               version: 1,
               command: "/bin/bash",
               duration: 11.146430015564,
               shell: "/bin/zsh",
               terminal_type: "screen-256color",
               cols: 96,
               rows: 26,
               title: "bashing :)",
               uname: nil,
               user_agent: "a/user/agent"
             } = asciicast

      assert asciicast.path =~ ~r|\d\d/\d\d/#{asciicast.id}\.json$|
    end

    test "json file, v1 format (missing required data)" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "1/invalid.json"})

      assert {:error, %Ecto.Changeset{}} = Recordings.create_asciicast(user, upload)
    end

    test "json file, unsupported version number" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "5/asciicast.json"})

      assert {:error, {:unsupported_format, 5}} = Recordings.create_asciicast(user, upload)
    end

    test "cast file, v2 format, minimal" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "2/minimal.cast"})

      {:ok, asciicast} = Recordings.create_asciicast(user, upload, %{user_agent: "a/user/agent"})

      assert %Asciicast{
               version: 2,
               cols: 96,
               rows: 26,
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

      {:ok, asciicast} = Recordings.create_asciicast(user, upload, %{user_agent: "a/user/agent"})

      assert %Asciicast{
               version: 2,
               cols: 96,
               rows: 26,
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

      assert {:error, :unknown_format} = Recordings.create_asciicast(user, upload)
    end
  end

  describe "delete_asciicast/1" do
    test "v1/v2" do
      asciicast = insert(:asciicast_v1) |> with_file()
      assert {:ok, _asciicast} = Recordings.delete_asciicast(asciicast)

      asciicast = insert(:asciicast_v2) |> with_file()
      assert {:ok, _asciicast} = Recordings.delete_asciicast(asciicast)
    end
  end

  describe "generate_snapshot/2" do
    @tag :vt
    test "returns list of screen lines" do
      output = [{1.0, "a"}, {2.4, "b"}, {2.6, "c"}]
      snapshot = Recordings.generate_snapshot(output, 4, 2, 2.5)
      assert snapshot == [[["ab", %{}], [" ", %{"inverse" => true}], [" ", %{}]], [["    ", %{}]]]
    end
  end

  describe "upgrade/1" do
    test "keeps v1 and v2 intact" do
      asciicast_v1 = insert(:asciicast_v1)
      asciicast_v2 = insert(:asciicast_v2)

      assert ^asciicast_v1 = Recordings.upgrade(asciicast_v1)
      assert ^asciicast_v2 = Recordings.upgrade(asciicast_v2)
    end

    test "converts v0 file to v2" do
      asciicast = insert(:asciicast_v0) |> with_files()

      stream_v0 =
        asciicast
        |> Recordings.Output.stream()
        |> Enum.to_list()

      asciicast = Recordings.upgrade(asciicast)
      assert asciicast.version == 2
      assert asciicast.path =~ ~r|\d\d/\d\d/#{asciicast.id}\.cast$|

      stream_v2 =
        asciicast
        |> Recordings.Output.stream()
        |> Enum.to_list()

      assert stream_v0 == stream_v2
    end
  end

  describe "parse_markers/1" do
    test "returns markers for valid syntax" do
      result = Asciicast.parse_markers("1.0 - Intro\n2.5\n5.0 - Tips & Tricks\n")

      assert result == {:ok, [{1.0, "Intro"}, {2.5, ""}, {5.0, "Tips & Tricks"}]}
    end

    test "returns error for invalid syntax" do
      result = Asciicast.parse_markers("1.0 - Intro\nFoobar\n")

      assert result == {:error, 1}
    end
  end
end
