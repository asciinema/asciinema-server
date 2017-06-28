defmodule Asciinema.AsciicastsTest do
  use Asciinema.DataCase
  alias Asciinema.{Asciicasts, Asciicast}

  describe "create_asciicast/3" do
    test "json file, v0 format with uname" do
      user = fixture(:user)
      params = %{"meta" => %{"command" => "/bin/bash",
                             "duration" => 11.146430015564,
                             "shell" => "/bin/zsh",
                             "terminal_columns" => 96,
                             "terminal_lines" => 26,
                             "terminal_type" => "screen-256color",
                             "title" => "bashing :)",
                             "uname" => "Linux 3.9.9-302.fc19.x86_64 #1 SMP Sat Jul 6 13:41:07 UTC 2013 x86_64"},
                 "stdout" => fixture(:upload, %{path: "0.9.7/stdout",
                                                content_type: "application/octet-stream"}),
                 "stdout_timing" => fixture(:upload, %{path: "0.9.7/stdout.time",
                                                       content_type: "application/octet-stream"})}

      {:ok, asciicast} = Asciicasts.create_asciicast(user, params, "a/user/agent")

      assert %Asciicast{version: 0,
                        file: nil,
                        stdout_data: "stdout",
                        stdout_timing: "stdout.time",
                        command: "/bin/bash",
                        duration: 11.146430015564,
                        shell: "/bin/zsh",
                        terminal_type: "screen-256color",
                        terminal_columns: 96,
                        terminal_lines: 26,
                        title: "bashing :)",
                        uname: "Linux 3.9.9-302.fc19.x86_64 #1 SMP Sat Jul 6 13:41:07 UTC 2013 x86_64",
                        user_agent: nil} = asciicast
    end

    test "json file, v0 format without uname" do
      user = fixture(:user)
      params = %{"meta" => %{"command" => "/bin/bash",
                             "duration" => 11.146430015564,
                             "shell" => "/bin/zsh",
                             "terminal_columns" => 96,
                             "terminal_lines" => 26,
                             "terminal_type" => "screen-256color",
                             "title" => "bashing :)"},
                 "stdout" => fixture(:upload, %{path: "0.9.8/stdout",
                                                content_type: "application/octet-stream"}),
                 "stdout_timing" => fixture(:upload, %{path: "0.9.8/stdout.time",
                                                       content_type: "application/octet-stream"})}

      {:ok, asciicast} = Asciicasts.create_asciicast(user, params, "a/user/agent")

      assert %Asciicast{version: 0,
                        file: nil,
                        stdout_data: "stdout",
                        stdout_timing: "stdout.time",
                        command: "/bin/bash",
                        duration: 11.146430015564,
                        shell: "/bin/zsh",
                        terminal_type: "screen-256color",
                        terminal_columns: 96,
                        terminal_lines: 26,
                        title: "bashing :)",
                        uname: nil,
                        user_agent: "a/user/agent"} = asciicast
    end

    test "json file, v1 format" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "1/asciicast.json"})

      {:ok, asciicast} = Asciicasts.create_asciicast(user, upload, "a/user/agent")

      assert %Asciicast{version: 1,
                        file: "asciicast.json",
                        stdout_data: nil,
                        stdout_timing: nil,
                        command: "/bin/bash",
                        duration: 11.146430015564,
                        shell: "/bin/zsh",
                        terminal_type: "screen-256color",
                        terminal_columns: 96,
                        terminal_lines: 26,
                        title: "bashing :)",
                        uname: nil,
                        user_agent: "a/user/agent"} = asciicast
    end

    test "json file, v1 format (missing required data)" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "1/invalid.json"})

      assert {:error, %Ecto.Changeset{}} = Asciicasts.create_asciicast(user, upload)
    end

    test "json file, unsupported version number" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "5/asciicast.json"})

      assert {:error, :unknown_format} = Asciicasts.create_asciicast(user, upload)
    end

    test "non-json file" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "new-logo-bars.png"})

      assert {:error, :parse_error} = Asciicasts.create_asciicast(user, upload)
    end
  end

  describe "stdout_stream/1" do
    test "with asciicast v1 file" do
      stream = Asciicasts.stdout_stream("spec/fixtures/1/asciicast.json")
      assert :ok == Stream.run(stream)
      assert [{1.234567, "foo bar"}, {5.678987, "baz qux"}] == Enum.take(stream, 2)
    end
  end

  describe "stdout_stream/2" do
    test "with gzipped files" do
      stream = Asciicasts.stdout_stream("spec/fixtures/0.9.9/stdout.time",
                                        "spec/fixtures/0.9.9/stdout")
      assert :ok == Stream.run(stream)
      assert [{1.234567, "foobar"}, {0.123456, "baz"}] == Enum.take(stream, 2)
    end

    test "with bzipped files" do
      stream = Asciicasts.stdout_stream("spec/fixtures/0.9.8/stdout.time",
                                        "spec/fixtures/0.9.8/stdout")
      assert :ok == Stream.run(stream)
      assert [{1.234567, "foobar"}, {0.123456, "baz"}] == Enum.take(stream, 2)
    end
  end
end
