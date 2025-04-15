defmodule Asciinema.RecordingsTest do
  use Asciinema.DataCase
  import Asciinema.Factory
  alias Asciinema.Recordings
  alias Asciinema.Recordings.Asciicast

  describe "create_asciicast/3" do
    test "json file, v1 format" do
      user = insert(:user)
      cli = insert(:cli, user: user)
      cli_id = cli.id
      upload = fixture(:upload, %{path: "1/full.json"})

      {:ok, asciicast} =
        Recordings.create_asciicast(user, upload, %{cli_id: cli_id, user_agent: "a/user/agent"})

      assert %Asciicast{
               version: 1,
               command: "/bin/bash",
               duration: 11.146430,
               shell: "/bin/zsh",
               term_type: "screen-256color",
               term_cols: 96,
               term_rows: 26,
               title: "bashing :)",
               uname: nil,
               user_agent: "a/user/agent",
               cli_id: ^cli_id
             } = asciicast

      assert asciicast.path =~ ~r|^recordings/.+\.json$|
    end

    test "json file, v1 format (missing required data)" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "1/invalid.json"})

      assert {:error, %Ecto.Changeset{}} = Recordings.create_asciicast(user, upload)
    end

    test "json file, unsupported version number" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "5/asciicast.json"})

      assert {:error, {:invalid_version, 5}} = Recordings.create_asciicast(user, upload)
    end

    test "cast file, v2 format, minimal" do
      user = insert(:user)
      cli = insert(:cli, user: user)
      cli_id = cli.id
      upload = fixture(:upload, %{path: "2/minimal.cast"})

      {:ok, asciicast} =
        Recordings.create_asciicast(user, upload, %{cli_id: cli_id, user_agent: "a/user/agent"})

      assert %Asciicast{
               version: 2,
               term_cols: 96,
               term_rows: 26,
               term_type: nil,
               term_theme_fg: nil,
               term_theme_bg: nil,
               term_theme_palette: nil,
               duration: 8.456789,
               command: nil,
               recorded_at: nil,
               shell: nil,
               title: nil,
               idle_time_limit: nil,
               uname: nil,
               user_agent: "a/user/agent",
               cli_id: ^cli_id
             } = asciicast

      assert asciicast.path =~ ~r|^recordings/.+\.cast$|
    end

    test "cast file, v2 format, full" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "2/full.cast"})

      {:ok, asciicast} = Recordings.create_asciicast(user, upload, %{user_agent: "a/user/agent"})

      assert %Asciicast{
               version: 2,
               term_cols: 96,
               term_rows: 26,
               duration: 7.34567,
               command: "/bin/bash -l",
               shell: "/bin/zsh",
               term_type: "screen-256color",
               title: "bashing :)",
               term_theme_fg: "#aaaaaa",
               term_theme_bg: "#bbbbbb",
               term_theme_palette:
                 "#151515:#ac4142:#7e8e50:#e5b567:#6c99bb:#9f4e85:#7dd6cf:#d0d0d0:#505050:#ac4142:#7e8e50:#e5b567:#6c99bb:#9f4e85:#7dd6cf:#f5f5f5",
               idle_time_limit: 2.5,
               uname: nil,
               user_agent: "a/user/agent"
             } = asciicast

      assert asciicast.path =~ ~r|^recordings/.+\.cast$|
      assert DateTime.to_unix(asciicast.recorded_at) == 1_506_410_422
    end

    test "invalid file format" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "favicon.png"})

      assert {:error, :invalid_format} = Recordings.create_asciicast(user, upload)
    end
  end

  describe "ensure_welcome_asciicast/1" do
    test "works" do
      user = insert(:user)

      assert Recordings.ensure_welcome_asciicast(user) == :ok
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

  describe "event_stream/1" do
    test "with asciicast v1 file" do
      asciicast = insert(:asciicast_v1) |> with_file()

      stream = Recordings.event_stream(asciicast)

      assert Enum.count(stream) == 785
    end

    test "with asciicast v2 file" do
      asciicast = insert(:asciicast_v2) |> with_file()

      stream = Recordings.event_stream(asciicast)

      assert Enum.count(stream) == 786
    end
  end

  describe "generate_snapshot/2" do
    @tag :vt
    test "returns list of screen lines" do
      output = [{1.0, "a"}, {2.4, "b"}, {2.6, "c"}]
      snapshot = Recordings.generate_snapshot(output, 4, 2, 2.5)

      assert snapshot ==
               {[
                  [{"ab  ", %{}, 1}],
                  [{"    ", %{}, 1}]
                ], {2, 0}}
    end
  end

  describe "migrate_file/1" do
    test "is noop when the file path is up to date" do
      asciicast =
        :asciicast
        |> insert()
        |> Recordings.assign_path()
        |> with_file()

      assert ^asciicast = Recordings.migrate_file(asciicast)
    end

    test "moves the file when the path is stale" do
      asciicast =
        :asciicast
        |> insert()
        |> with_file()

      old_path = asciicast.path

      asciicast = Recordings.migrate_file(asciicast)

      assert asciicast.path != old_path
    end
  end
end
