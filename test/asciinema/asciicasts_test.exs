defmodule Asciinema.AsciicastsTest do
  use Asciinema.DataCase
  alias Asciinema.Asciicasts

  describe "create_asciicast/2" do
    test "json file, v0 format, <= v0.9.7 client" do
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

      assert asciicast.version == 0
      assert asciicast.file == nil
      assert asciicast.stdout_data == "stdout"
      assert asciicast.stdout_timing == "stdout.time"
      assert asciicast.command == "/bin/bash"
      assert asciicast.duration == 11.146430015564
      assert asciicast.shell == "/bin/zsh"
      assert asciicast.terminal_type == "screen-256color"
      assert asciicast.terminal_columns == 96
      assert asciicast.terminal_lines == 26
      assert asciicast.title == "bashing :)"
      assert asciicast.uname == "Linux 3.9.9-302.fc19.x86_64 #1 SMP Sat Jul 6 13:41:07 UTC 2013 x86_64"
      assert asciicast.user_agent == nil
    end

    test "json file, v1 format" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "1/asciicast.json"})

      {:ok, asciicast} = Asciicasts.create_asciicast(user, upload, "a/user/agent")

      assert asciicast.version == 1
      assert asciicast.file == "asciicast.json"
      assert asciicast.stdout_data == nil
      assert asciicast.stdout_timing == nil
      assert asciicast.command == "/bin/bash"
      assert asciicast.duration == 11.146430015564
      assert asciicast.shell == "/bin/zsh"
      assert asciicast.terminal_type == "screen-256color"
      assert asciicast.terminal_columns == 96
      assert asciicast.terminal_lines == 26
      assert asciicast.title == "bashing :)"
      assert asciicast.uname == nil
      assert asciicast.user_agent == "a/user/agent"
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
end
