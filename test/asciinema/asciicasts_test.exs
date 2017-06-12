defmodule Asciinema.AsciicastsTest do
  use Asciinema.DataCase
  alias Asciinema.Asciicasts

  describe "create_asciicast/2" do
    test "json file, v1 format" do
      user = fixture(:user)
      upload = fixture(:upload, %{path: "1/asciicast.json"})

      {:ok, asciicast} = Asciicasts.create_asciicast(user, upload)

      assert asciicast.version == 1
      assert asciicast.file == "asciicast.json"
      assert asciicast.command == "/bin/bash"
      assert asciicast.duration == 11.146430015564
      assert asciicast.shell == "/bin/zsh"
      assert asciicast.terminal_type == "screen-256color"
      assert asciicast.terminal_columns == 96
      assert asciicast.terminal_lines == 26
      assert asciicast.title == "bashing :)"
      assert asciicast.uname == nil
      # TODO assert asciicast.user_agent == "asciinema/1.0.0 gc/go1.3 jola-amd64"
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
