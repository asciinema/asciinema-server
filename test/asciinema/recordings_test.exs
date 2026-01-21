defmodule Asciinema.RecordingsTest do
  use Asciinema.DataCase, async: true
  import Asciinema.Factory
  alias Asciinema.Recordings
  alias Asciinema.Recordings.{Asciicast, AsciicastStats}

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
               duration: 10.370343,
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

    test "default settings from user" do
      user =
        insert(:user,
          term_theme_name: nil,
          term_theme_prefer_original: false,
          term_bold_is_bright: false,
          default_recording_visibility: :public
        )

      upload = fixture(:upload, %{path: "3/full.cast"})
      {:ok, asciicast} = Recordings.create_asciicast(user, upload)

      assert %Asciicast{
               term_theme_name: nil,
               term_font_family: nil,
               term_bold_is_bright: false,
               visibility: :public
             } = asciicast

      user =
        insert(:user,
          term_theme_name: "dracula",
          term_theme_prefer_original: false,
          term_bold_is_bright: true,
          default_recording_visibility: :private
        )

      upload = fixture(:upload, %{path: "3/full.cast"})
      {:ok, asciicast} = Recordings.create_asciicast(user, upload)

      assert %Asciicast{
               term_theme_name: nil,
               term_theme_palette: "#" <> _,
               term_bold_is_bright: true,
               visibility: :private
             } = asciicast

      user =
        insert(:user,
          term_theme_name: "dracula",
          term_theme_prefer_original: true,
          default_recording_visibility: :private
        )

      upload = fixture(:upload, %{path: "3/full.cast"})
      {:ok, asciicast} = Recordings.create_asciicast(user, upload)

      assert %Asciicast{
               term_theme_name: "original",
               term_theme_palette: "#" <> _,
               visibility: :private
             } = asciicast
    end
  end

  describe "lookup_asciicast/1" do
    test "accepts numerical ID for public recordings" do
      asciicast = insert(:asciicast, visibility: :public)
      id = asciicast.id

      assert %Asciicast{id: ^id} = Recordings.lookup_asciicast(to_string(id))
      assert nil == Recordings.lookup_asciicast("999999999999")
    end

    test "allows non-public lookup by numerical ID when enabled" do
      asciicast = insert(:asciicast, visibility: :unlisted)
      id = asciicast.id

      assert nil == Recordings.lookup_asciicast(to_string(id))
      assert %Asciicast{id: ^id} = Recordings.lookup_asciicast(to_string(id), true)
    end

    test "accepts current 16-char secret tokens" do
      asciicast = insert(:asciicast, secret_token: "abcdefghijklmnop")
      id = asciicast.id

      assert %Asciicast{id: ^id} = Recordings.lookup_asciicast("abcdefghijklmnop")

      assert nil == Recordings.lookup_asciicast("zzzzzzzzzzzzzzzz")
    end

    test "accepts legacy 25-char secret tokens" do
      asciicast = insert(:asciicast, secret_token: "abcdefghijklmnopqrstuvwxy")
      id = asciicast.id

      assert %Asciicast{id: ^id} = Recordings.lookup_asciicast("abcdefghijklmnopqrstuvwxy")

      assert nil == Recordings.lookup_asciicast("zzzzzzzzzzzzzzzzzzzzzzzzz")
    end
  end

  describe "ensure_welcome_asciicast/1" do
    test "works" do
      user = insert(:user)

      assert Recordings.ensure_welcome_asciicast(user) == :ok
    end
  end

  describe "query/2" do
    test "filters popular recordings to public items with positive scores" do
      popular = insert(:asciicast, visibility: :public)
      insert(:asciicast_stats, asciicast_id: popular.id, popularity_score: 1.0)

      zero = insert(:asciicast, visibility: :public)
      insert(:asciicast_stats, asciicast_id: zero.id, popularity_score: 0.0)

      private = insert(:asciicast, visibility: :private)
      insert(:asciicast_stats, asciicast_id: private.id, popularity_score: 2.0)

      archived = insert(:asciicast, visibility: :public, archived_at: DateTime.utc_now())
      insert(:asciicast_stats, asciicast_id: archived.id, popularity_score: 3.0)

      results =
        :popular
        |> Recordings.query()
        |> Recordings.list(10)

      assert Enum.map(results, & &1.id) == [popular.id]
    end

    test "orders by popularity score then id" do
      low = insert(:asciicast)
      insert(:asciicast_stats, asciicast_id: low.id, popularity_score: 5.0)

      mid = insert(:asciicast)
      insert(:asciicast_stats, asciicast_id: mid.id, popularity_score: 5.0)

      high = insert(:asciicast)
      insert(:asciicast_stats, asciicast_id: high.id, popularity_score: 10.0)

      results =
        []
        |> Recordings.query(:popularity)
        |> Recordings.list(10)

      assert Enum.map(results, & &1.id) == [high.id, mid.id, low.id]
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

  describe "generate_snapshot/4" do
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

  describe "generate_fts_content/3" do
    @tag :vt
    test "returns recording content prepared for FTS" do
      output = [{1.0, "o", "a"}, {2.4, "o", "B"}, {2.6, "o", "c"}]
      content = Recordings.generate_fts_content(output, 10, 5)

      assert content == "abc "
    end

    @tag :vt
    test "includes scrollback" do
      output = [{1.0, "o", "aaa\n"}, {2.4, "o", "Bbb\n"}, {2.6, "o", "ccc\n"}]
      content = Recordings.generate_fts_content(output, 10, 2)

      assert content == "aaa bbb ccc "
    end

    @tag :vt
    test "keeps words of len > 1, truncates words > 32" do
      output = [
        {1.0, "o", "a "},
        {2.4, "o", "bbbbbbbbbbBbbbbbbbbbbbbbbbbbbB "},
        {2.6, "o", "CcccccccccccccccccCcccccccccccccccccccCc "}
      ]

      content = Recordings.generate_fts_content(output, 100, 5)

      assert content == "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb cccccccccccccccccccccccccccccccc "
    end

    @tag :vt
    test "alt screen buffer" do
      output = [
        # print on primary buffer
        "nvim\r\n",
        # switch to alternate buffer
        "\x1b[?1047h",
        # print
        "hello ",
        # print
        "w",
        # print
        "o",
        # print
        "r",
        # print
        "l",
        # print
        "d",
        # move back 2 chars
        "\x08\x08",
        # print
        "mz",
        # print
        " planet",
        # move back to the beginning of "wormz"
        "\x1b[12D",
        # overwrite "wormz"
        "wyrm ",
        # enable insert mode
        "\x1b[4h",
        # insert "foo bar baz"
        " foo bar baz ",
        # switch back to primary buffer
        "\x1b[?1047l",
        # print
        "bye!"
      ]

      events = for {text, i} <- Enum.with_index(output), do: {i, "o", text}

      content = Recordings.generate_fts_content(events, 50, 10)

      assert content == "nvim bye world wormz hello wyrm foo bar baz planet "
    end
  end

  describe "update_fts_content/1" do
    test "small file" do
      asciicast = insert(:asciicast) |> with_file()

      assert Recordings.update_fts_content(asciicast) == :ok
    end

    test "big file" do
      asciicast = insert(:asciicast_v3) |> with_file("big.cast")

      assert Recordings.update_fts_content(asciicast) == :ok
    end
  end

  describe "register_view/1" do
    test "increments total_views on stats" do
      asciicast = insert(:asciicast)

      insert(:asciicast_stats,
        asciicast_id: asciicast.id,
        total_views: 5,
        popularity_dirty: false
      )

      assert {:ok, :ok} = Recordings.register_view(asciicast)

      stats = Repo.get!(AsciicastStats, asciicast.id)
      assert stats.total_views == 6
      assert stats.popularity_dirty == true
    end

    test "creates daily view record for today" do
      asciicast = insert(:asciicast)
      today = Date.utc_today()

      assert {:ok, :ok} = Recordings.register_view(asciicast, today)

      [daily_view] =
        Repo.all(
          from(dv in "asciicast_daily_views",
            where: dv.asciicast_id == ^asciicast.id and dv.date == ^today,
            select: %{date: dv.date, count: dv.count}
          )
        )

      assert daily_view.date == today
      assert daily_view.count == 1
    end

    test "increments existing daily view count for today" do
      asciicast = insert(:asciicast)
      today = Date.utc_today()

      Recordings.register_view(asciicast, today)
      Recordings.register_view(asciicast, today)
      Recordings.register_view(asciicast, today)

      [daily_view] =
        Repo.all(
          from(dv in "asciicast_daily_views",
            where: dv.asciicast_id == ^asciicast.id and dv.date == ^today,
            select: %{date: dv.date, count: dv.count}
          )
        )

      assert daily_view.count == 3
    end

    test "marks asciicast as dirty for popularity recomputation" do
      asciicast = insert(:asciicast)

      insert(:asciicast_stats,
        asciicast_id: asciicast.id,
        popularity_dirty: false
      )

      assert {:ok, :ok} = Recordings.register_view(asciicast)

      stats = Repo.get!(AsciicastStats, asciicast.id)
      assert stats.popularity_dirty == true
    end
  end

  describe "recompute_popularity_scores/1" do
    test "recomputes only for dirty asciicasts" do
      today = Date.utc_today()
      asciicast = insert(:asciicast, visibility: :public)
      insert(:asciicast_stats, asciicast_id: asciicast.id, popularity_dirty: true)

      stale = insert(:asciicast, visibility: :public)
      insert(:asciicast_stats, asciicast_id: stale.id, popularity_dirty: true)

      other = insert(:asciicast, visibility: :public)
      insert(:asciicast_stats, asciicast_id: other.id, popularity_score: 9.9)

      Repo.insert_all("asciicast_daily_views", [
        %{asciicast_id: asciicast.id, date: today, count: 4},
        %{asciicast_id: stale.id, date: Date.add(today, -100), count: 9}
      ])

      assert {:ok, 1} = Recordings.recompute_popularity_scores(:dirty)

      asciicast = Repo.get!(AsciicastStats, asciicast.id)
      stale = Repo.get!(AsciicastStats, stale.id)
      other = Repo.get!(AsciicastStats, other.id)

      assert asciicast.popularity_score == 4.0
      assert stale.popularity_score == 0.0
      assert other.popularity_score == 9.9
      refute asciicast.popularity_dirty
      refute stale.popularity_dirty
    end

    test "recomputes for all asciicasts" do
      today = Date.utc_today()
      asciicast = insert(:asciicast, visibility: :public)
      insert(:asciicast_stats, asciicast_id: asciicast.id, popularity_dirty: false)

      other = insert(:asciicast, visibility: :public)
      insert(:asciicast_stats, asciicast_id: other.id, popularity_score: 5.5)

      Repo.insert_all("asciicast_daily_views", [
        %{asciicast_id: asciicast.id, date: today, count: 3}
      ])

      assert {:ok, 1} = Recordings.recompute_popularity_scores(:all)

      asciicast = Repo.get!(AsciicastStats, asciicast.id)
      other = Repo.get!(AsciicastStats, other.id)

      assert asciicast.popularity_score == 3.0
      assert other.popularity_score == 0.0
      refute asciicast.popularity_dirty
      refute other.popularity_dirty
    end

    test "applies exponential decay to older views" do
      today = Date.utc_today()
      asciicast = insert(:asciicast, visibility: :public)
      insert(:asciicast_stats, asciicast_id: asciicast.id, popularity_dirty: false)

      # Views from exactly 7 days ago (one half-life) should be halved
      # Views from exactly 14 days ago (two half-lives) should be quartered
      Repo.insert_all("asciicast_daily_views", [
        %{asciicast_id: asciicast.id, date: today, count: 100},
        %{asciicast_id: asciicast.id, date: Date.add(today, -7), count: 100},
        %{asciicast_id: asciicast.id, date: Date.add(today, -14), count: 100}
      ])

      assert {:ok, 1} = Recordings.recompute_popularity_scores(:all)

      asciicast = Repo.get!(AsciicastStats, asciicast.id)

      # Expected: 100 * 1.0 + 100 * 0.5 + 100 * 0.25 = 175.0
      assert asciicast.popularity_score == 175.0
    end

    test "excludes archived asciicasts from recomputation" do
      today = Date.utc_today()

      archived =
        insert(:asciicast, visibility: :public, archived_at: DateTime.utc_now())

      insert(:asciicast_stats,
        asciicast_id: archived.id,
        popularity_score: 99.0,
        popularity_dirty: true
      )

      active = insert(:asciicast, visibility: :public)
      insert(:asciicast_stats, asciicast_id: active.id, popularity_dirty: true)

      Repo.insert_all("asciicast_daily_views", [
        %{asciicast_id: archived.id, date: today, count: 50},
        %{asciicast_id: active.id, date: today, count: 10}
      ])

      # Test :all scope
      assert {:ok, 1} = Recordings.recompute_popularity_scores(:all)

      archived = Repo.get!(AsciicastStats, archived.id)
      active = Repo.get!(AsciicastStats, active.id)

      # Archived should be untouched
      assert archived.popularity_score == 99.0
      assert archived.popularity_dirty == true

      # Active should be updated
      assert active.popularity_score == 10.0
      refute active.popularity_dirty
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
