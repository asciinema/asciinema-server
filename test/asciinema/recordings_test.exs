defmodule Asciinema.RecordingsTest do
  use Asciinema.DataCase, async: true
  import Asciinema.Factory
  import Asciinema.ZstdTestHelpers
  alias Asciinema.Recordings
  alias Asciinema.Recordings.{Asciicast, AsciicastStats, Query}

  describe "create_asciicast/3" do
    test "json file, v1 format" do
      user = insert(:user)
      cli = insert(:cli, user: user)
      cli_id = cli.id
      upload = fixture(:upload, %{path: "1/full.json"})

      {:ok, asciicast} =
        Recordings.create_asciicast(user, upload.path, %{
          cli_id: cli_id,
          user_agent: "a/user/agent"
        })

      assert %Asciicast{
               version: 1,
               compressed: true,
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

      assert asciicast.path =~ ~r|^recordings/.+\.json\.zst$|
    end

    test "json file, v1 format (missing required data)" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "1/invalid.json"})

      assert {:error, %Ecto.Changeset{}} = Recordings.create_asciicast(user, upload.path)
    end

    test "json file, unsupported version number" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "5/asciicast.json"})

      assert {:error, {:invalid_version, 5}} = Recordings.create_asciicast(user, upload.path)
    end

    test "cast file, v2 format, minimal" do
      user = insert(:user)
      cli = insert(:cli, user: user)
      cli_id = cli.id
      upload = fixture(:upload, %{path: "2/minimal.cast"})

      {:ok, asciicast} =
        Recordings.create_asciicast(user, upload.path, %{
          cli_id: cli_id,
          user_agent: "a/user/agent"
        })

      assert %Asciicast{
               version: 2,
               compressed: true,
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

      assert asciicast.path =~ ~r|^recordings/.+\.cast\.zst$|
    end

    test "cast file, v2 format, full" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "2/full.cast"})

      {:ok, asciicast} =
        Recordings.create_asciicast(user, upload.path, %{user_agent: "a/user/agent"})

      assert %Asciicast{
               version: 2,
               compressed: true,
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

      assert asciicast.path =~ ~r|^recordings/.+\.cast\.zst$|
      assert DateTime.to_unix(asciicast.recorded_at) == 1_506_410_422
    end

    test "stores compressed and uncompressed file sizes for new uploads" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "2/full.cast"})
      expected_uncompressed_size = File.stat!(upload.path).size

      {:ok, asciicast} = Recordings.create_asciicast(user, upload.path)

      stored_path = Recordings.get_cast_path!(asciicast)
      expected_compressed_size = File.stat!(stored_path).size

      assert asciicast.uncompressed_size == expected_uncompressed_size
      assert asciicast.compressed_size == expected_compressed_size
    end

    test "invalid file format" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "favicon.png"})

      assert {:error, :invalid_format} = Recordings.create_asciicast(user, upload.path)
    end

    test "compressed upload" do
      user = insert(:user)

      zstd_path = zstd_fixture!("test/fixtures/2/full.cast")

      gzip_path = Briefly.create!()
      File.write!(gzip_path, :zlib.gzip(File.read!("test/fixtures/2/full.cast")))

      assert {:error, :invalid_format} = Recordings.create_asciicast(user, zstd_path)
      assert {:error, :invalid_format} = Recordings.create_asciicast(user, gzip_path)
    end

    test "syntax error in asciicast v2 file" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "2/broken.cast"})

      assert {:error, :invalid_format} = Recordings.create_asciicast(user, upload.path)
    end

    test "syntax error in asciicast v3 file" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "3/broken.cast"})

      assert {:error, :invalid_format} = Recordings.create_asciicast(user, upload.path)
    end

    test "default settings from user" do
      user =
        insert(:user,
          term_theme_name: nil,
          term_theme_prefer_original: false,
          term_bold_is_bright: false,
          term_adaptive_palette: false,
          default_recording_visibility: :public
        )

      upload = fixture(:upload, %{path: "3/full.cast"})
      {:ok, asciicast} = Recordings.create_asciicast(user, upload.path)

      assert %Asciicast{
               term_theme_name: nil,
               term_font_family: nil,
               term_bold_is_bright: false,
               term_adaptive_palette: false,
               visibility: :public
             } = asciicast

      user =
        insert(:user,
          term_theme_name: "dracula",
          term_theme_prefer_original: false,
          term_bold_is_bright: true,
          term_adaptive_palette: true,
          default_recording_visibility: :private
        )

      upload = fixture(:upload, %{path: "3/full.cast"})
      {:ok, asciicast} = Recordings.create_asciicast(user, upload.path)

      assert %Asciicast{
               term_theme_name: nil,
               term_theme_palette: "#" <> _,
               term_bold_is_bright: true,
               term_adaptive_palette: true,
               visibility: :private
             } = asciicast

      user =
        insert(:user,
          term_theme_name: "dracula",
          term_theme_prefer_original: true,
          default_recording_visibility: :private
        )

      upload = fixture(:upload, %{path: "3/full.cast"})
      {:ok, asciicast} = Recordings.create_asciicast(user, upload.path)

      assert %Asciicast{
               term_theme_name: "original",
               term_theme_palette: "#" <> _,
               visibility: :private
             } = asciicast
    end

    test "explicit terminal render options override user defaults" do
      user =
        insert(:user,
          term_bold_is_bright: false,
          term_adaptive_palette: false
        )

      upload = fixture(:upload, %{path: "3/full.cast"})

      {:ok, asciicast} =
        Recordings.create_asciicast(user, upload.path, %{
          term_bold_is_bright: true,
          term_adaptive_palette: true
        })

      assert %Asciicast{
               term_bold_is_bright: true,
               term_adaptive_palette: true
             } = asciicast
    end

    test "uses fresh username for path generation when user struct is stale" do
      user = insert(:user, username: "old-username")
      upload = fixture(:upload, %{path: "2/full.cast"})

      Repo.update_all(
        from(u in "users", where: u.id == ^user.id),
        set: [username: "new-username"]
      )

      {:ok, asciicast} = Recordings.create_asciicast(user, upload.path)

      assert asciicast.path =~ "recordings/new-username/"
      refute asciicast.path =~ "recordings/old-username/"
    end

    test "stores filename from params" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "2/full.cast"})

      {:ok, asciicast} =
        Recordings.create_asciicast(user, upload.path, %{}, %{"filename" => "my-recording.cast"})

      assert asciicast.filename == "my-recording.cast"
    end

    test "strips path components from filename" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "2/full.cast"})

      {:ok, asciicast} =
        Recordings.create_asciicast(user, upload.path, %{}, %{
          "filename" => "../../etc/passwd/evil.cast"
        })

      assert asciicast.filename == "evil.cast"
    end

    test "truncates very long filenames" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "2/full.cast"})
      long_name = String.duplicate("a", 1000) <> ".cast"

      {:ok, asciicast} =
        Recordings.create_asciicast(user, upload.path, %{}, %{"filename" => long_name})

      assert byte_size(asciicast.filename) == 255
    end

    test "uses fallback filename when filename is missing" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "2/full.cast"})

      {:ok, asciicast} = Recordings.create_asciicast(user, upload.path)

      assert asciicast.filename == "asciicast.cast"
    end

    test "uses fallback filename when filename is not a binary" do
      user = insert(:user)
      upload = fixture(:upload, %{path: "2/full.cast"})

      {:ok, asciicast} =
        Recordings.create_asciicast(user, upload.path, %{}, %{"filename" => 123})

      assert asciicast.filename == "asciicast.cast"
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

      assert %Asciicast{id: ^id} =
               Recordings.lookup_asciicast(to_string(id), allow_non_public_id: true)
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

    test "does not load snapshot by default" do
      snapshot = {[[{"test", %{}, 1}]], {0, 0}}
      asciicast = insert(:asciicast, visibility: :public, snapshot: snapshot)
      id = to_string(asciicast.id)

      result = Recordings.lookup_asciicast(id)
      assert result.id == asciicast.id
      assert result.snapshot == nil
    end

    test "loads snapshot when load_snapshot: true" do
      snapshot = {[[{"test", %{}, 1}]], {0, 0}}
      asciicast = insert(:asciicast, visibility: :public, snapshot: snapshot)
      id = to_string(asciicast.id)

      result = Recordings.lookup_asciicast(id, load_snapshot: true)
      assert result.id == asciicast.id
      assert %Asciinema.Recordings.Snapshot{} = result.snapshot
      assert length(result.snapshot.lines) == 1
    end
  end

  describe "query/1" do
    test "requires an explicit scope" do
      assert_raise ArgumentError, fn ->
        struct!(Query, filters: [])
      end
    end

    test "applies public and listing scopes" do
      owner = insert(:user)
      viewer = insert(:user)

      public = insert(:asciicast, user: owner, visibility: :public)
      unlisted = insert(:asciicast, user: owner, visibility: :unlisted)
      private = insert(:asciicast, user: owner, visibility: :private)

      public_ids =
        %Query{scope: :public_listing}
        |> Recordings.list(10)
        |> Enum.map(& &1.id)

      viewer_ids =
        %Query{scope: {:listing_for, viewer}}
        |> Recordings.list(10)
        |> Enum.map(& &1.id)

      anonymous_ids =
        %Query{scope: {:listing_for, nil}}
        |> Recordings.list(10)
        |> Enum.map(& &1.id)

      owner_ids =
        %Query{scope: {:listing_for, owner}}
        |> Recordings.list(10)
        |> Enum.map(& &1.id)

      assert public.id in public_ids
      refute unlisted.id in public_ids
      refute private.id in public_ids

      assert Enum.sort(public_ids) == Enum.sort(viewer_ids)
      assert Enum.sort(public_ids) == Enum.sort(anonymous_ids)
      assert public.id in owner_ids
      assert unlisted.id in owner_ids
      assert private.id in owner_ids
    end

    test "applies archived mode" do
      active = insert(:asciicast, archived_at: nil)
      archived = insert(:asciicast, archived_at: ~U[2025-01-01 00:00:00Z])

      exclude_ids =
        %Query{scope: :system, archived: :exclude}
        |> Recordings.list(10)
        |> Enum.map(& &1.id)

      include_ids =
        %Query{scope: :system, archived: :include}
        |> Recordings.list(10)
        |> Enum.map(& &1.id)

      only_ids =
        %Query{scope: :system, archived: :only}
        |> Recordings.list(10)
        |> Enum.map(& &1.id)

      assert active.id in exclude_ids
      refute archived.id in exclude_ids

      assert active.id in include_ids
      assert archived.id in include_ids

      refute active.id in only_ids
      assert archived.id in only_ids
    end

    test "filters by token (exact secret_token match)" do
      target = insert(:asciicast, secret_token: "tok-target-aaaaaaaa")
      insert(:asciicast, secret_token: "tok-other-bbbbbbbbbb")

      results =
        %Query{scope: :admin, archived: :include, filters: [{:token, "tok-target-aaaaaaaa"}]}
        |> Recordings.list(10)

      assert Enum.map(results, & &1.id) == [target.id]
    end

    test "filters by user, id exclusion, featured, and snapshotless" do
      user = insert(:user)
      other_user = insert(:user)

      target =
        insert(:asciicast,
          user: user,
          featured: true,
          snapshot: nil
        )

      excluded =
        insert(:asciicast,
          user: user,
          featured: true,
          snapshot: nil
        )

      insert(:asciicast, user: other_user, featured: true, snapshot: nil)
      insert(:asciicast, user: user, featured: false, snapshot: nil)
      insert(:asciicast, user: user, featured: true)

      results =
        %Query{
          scope: :system,
          filters: [
            {:user, user},
            {:id, {:not_eq, excluded.id}},
            :featured,
            :snapshotless
          ]
        }
        |> Recordings.list(10)

      assert Enum.map(results, & &1.id) == [target.id]
    end

    test "filters by stream relation" do
      user = insert(:user)
      stream = insert(:stream)
      other_stream = insert(:stream)

      target = insert(:asciicast, user: user, stream_id: stream.id)
      excluded = insert(:asciicast, user: user, stream_id: other_stream.id)
      without_stream = insert(:asciicast, user: user, stream_id: nil)

      assert_ids = fn stream_filter, ids ->
        results =
          %Query{scope: :system, filters: [{:user, user}, stream_filter]}
          |> Recordings.list(10)

        assert Enum.map(results, & &1.id) |> Enum.sort() == Enum.sort(ids)
      end

      assert_ids.({:stream, stream}, [target.id])
      assert_ids.({:stream, stream.id}, [target.id])
      assert_ids.({:stream, true}, [target.id, excluded.id])
      assert_ids.({:stream, false}, [without_stream.id])
      assert_ids.({:stream, {:not_eq, other_stream.id}}, [target.id, without_stream.id])
      assert_ids.({:stream, {:in, [stream.id]}}, [target.id])
    end

    test "filters by id, public status, featured false, and audio presence" do
      user = insert(:user)

      public_audio =
        insert(:asciicast,
          user: user,
          visibility: :public,
          featured: false,
          audio_url: "https://example.com/audio"
        )

      private = insert(:asciicast, user: user, visibility: :private, featured: nil)
      public_featured = insert(:asciicast, user: user, visibility: :public, featured: true)

      assert_ids = fn filter, expected ->
        ids =
          %Query{
            scope: :system,
            archived: :include,
            filters: [{:user, user.id}, filter]
          }
          |> Recordings.list(10)
          |> Enum.map(& &1.id)
          |> Enum.sort()

        assert ids == Enum.sort(expected)
      end

      assert_ids.({:id, private.id}, [private.id])
      assert_ids.(:public, [public_audio.id, public_featured.id])
      assert_ids.({:featured, false}, [public_audio.id, private.id])
      assert_ids.({:audio, true}, [public_audio.id])
      assert_ids.({:audio, false}, [private.id, public_featured.id])
    end

    test "filters by created time, duration, size, and views" do
      user = insert(:user)

      low =
        insert(:asciicast,
          user: user,
          inserted_at: ~U[2025-01-01 00:00:00Z],
          duration: 10,
          compressed_size: 100
        )

      high =
        insert(:asciicast,
          user: user,
          inserted_at: ~U[2025-02-01 00:00:00Z],
          duration: 20,
          compressed_size: 200
        )

      insert(:asciicast_stats, asciicast_id: low.id, total_views: 5)
      insert(:asciicast_stats, asciicast_id: high.id, total_views: 15)

      assert_id = fn filter, expected ->
        assert [%{id: id}] =
                 %Query{
                   scope: :system,
                   archived: :include,
                   filters: [{:user, user.id}, filter]
                 }
                 |> Recordings.list(10)

        assert id == expected.id
      end

      assert_id.({:created_at, {:gte, ~U[2025-01-15 00:00:00Z]}}, high)
      assert_id.({:duration, {:between, 15, 25}}, high)
      assert_id.({:compressed_size, {:lt, 150}}, low)
      assert_id.({:views, {:gte, 10}}, high)
    end

    test "views filters count recordings without stats as zero views" do
      user = insert(:user)
      unviewed = insert(:asciicast, user: user)
      viewed = insert(:asciicast, user: user)
      insert(:asciicast_stats, asciicast_id: viewed.id, total_views: 5)

      list = fn filter ->
        %Query{scope: :system, archived: :include, filters: [{:user, user.id}, filter]}
        |> Recordings.list(10)
        |> Enum.map(& &1.id)
        |> Enum.sort()
      end

      assert list.({:views, {:eq, 0}}) == [unviewed.id]
      assert list.({:views, {:lt, 3}}) == [unviewed.id]
      assert list.({:views, {:gt, 0}}) == [viewed.id]
      assert list.({:views, {:between, 1, 10}}) == [viewed.id]
    end

    test "smoke-tests random sort" do
      user = insert(:user)

      insert(:asciicast, user: user)
      insert(:asciicast, user: user, stream_id: insert(:stream).id)

      results =
        %Query{scope: :system, filters: [{:user, user}], sort: :random}
        |> Recordings.list(10)

      assert length(results) == 2
    end

    test "searches title and full text" do
      title_match = insert(:asciicast, title: "Deploy Demo", description: "nothing")
      description_match = insert(:asciicast, title: "Other", description: "Deploy notes")

      content_match =
        insert(:asciicast_v3, title: "Other", description: "nothing")
        |> with_file()

      insert(:asciicast, title: "Other", description: "nothing")

      assert Recordings.update_fts_content(content_match) == :ok

      title_results =
        %Query{scope: :system, filters: [{:title, {:search, "deploy"}}]}
        |> Recordings.list(10)

      title_description_results =
        %Query{scope: :system, filters: [{:full_text, {:search, "deploy"}}]}
        |> Recordings.list(10)

      content_results =
        %Query{scope: :system, filters: [{:full_text, {:search, "foo"}}]}
        |> Recordings.list(10)

      title_description_ids =
        title_description_results
        |> Enum.map(& &1.id)
        |> Enum.sort()

      assert Enum.map(title_results, & &1.id) == [title_match.id]
      assert title_description_ids == Enum.sort([title_match.id, description_match.id])
      assert Enum.map(content_results, & &1.id) == [content_match.id]
    end

    test "rank sort requires a search filter" do
      assert_raise ArgumentError, fn ->
        %Query{scope: :system, sort: {:rank, :desc}}
        |> Recordings.list(10)
      end
    end

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
        %Query{scope: :public_listing, filters: [:popular]}
        |> Recordings.list(10)

      assert Enum.map(results, & &1.id) == [popular.id]
    end

    test "orders by popularity score then id" do
      low = insert(:asciicast, visibility: :public)
      insert(:asciicast_stats, asciicast_id: low.id, popularity_score: 5.0)

      mid = insert(:asciicast, visibility: :public)
      insert(:asciicast_stats, asciicast_id: mid.id, popularity_score: 5.0)

      high = insert(:asciicast, visibility: :public)
      insert(:asciicast_stats, asciicast_id: high.id, popularity_score: 10.0)

      results =
        %Query{scope: :public_listing, filters: [:popular], sort: {:popularity, :desc}}
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

  describe "compress_asciicast/1" do
    test "compresses a legacy asciicast and backfills sizes" do
      asciicast = insert(:asciicast_v2) |> with_file("2/full.cast")
      old_path = asciicast.path
      expected_uncompressed_size = File.stat!("test/fixtures/2/full.cast").size
      expected_event_count = Enum.count(Recordings.event_stream(asciicast))

      assert {:ok, %{id: id}} = Recordings.compress_asciicast(asciicast)

      asciicast = Recordings.get_asciicast(id)
      stored_path = Recordings.get_cast_path!(asciicast)

      assert asciicast.compressed == true
      assert asciicast.path =~ ~r|\.cast\.zst$|
      assert asciicast.path != old_path
      assert asciicast.uncompressed_size == expected_uncompressed_size
      assert asciicast.compressed_size == File.stat!(stored_path).size
      assert Enum.count(Recordings.event_stream(asciicast)) == expected_event_count
      assert Asciinema.FileStore.delete_file(old_path) == {:error, :enoent}
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

    test "with zstd-compressed asciicast file" do
      asciicast =
        insert(:asciicast_v2,
          compressed: true,
          path: "recordings/compressed/welcome.cast.zst"
        )

      path = zstd_fixture!("test/fixtures/welcome.cast")
      :ok = Asciinema.FileStore.put_file(asciicast.path, path, "application/x-asciicast")

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

  describe "paginate/4" do
    test "caps total entries and pages when max_pages is set" do
      user = insert(:user)
      insert_list(21, :asciicast, visibility: :public, user: user)

      page =
        %Query{scope: :system, filters: [{:user, user}], sort: {:created, :desc}}
        |> Recordings.paginate(11, 2, max_pages: 10)

      assert page.total_pages == 10
      assert page.total_entries == 20
      assert page.page_number == 10
      assert length(page.entries) == 2
    end

    test "doesn't cap pages when max_pages is not set" do
      user = insert(:user)
      insert_list(21, :asciicast, visibility: :public, user: user)

      page =
        %Query{scope: :system, filters: [{:user, user}], sort: {:created, :desc}}
        |> Recordings.paginate(11, 2)

      assert page.total_pages > 10
      assert page.page_number == 11
      assert page.total_entries == 21
    end
  end

  describe "migrate_file/1" do
    test "is noop when the file path is up to date" do
      asciicast =
        :asciicast
        |> insert()
        |> with_file()
        |> Recordings.migrate_file()

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

  describe "admin query execution" do
    test "includes recordings of every visibility, including archived" do
      user = insert(:user)
      insert(:asciicast, user: user, visibility: :private)
      insert(:asciicast, user: user, visibility: :unlisted)
      insert(:asciicast, user: user, visibility: :public)
      insert(:asciicast, user: user, archived_at: ~U[2025-01-01 00:00:00Z])

      results =
        %Query{scope: :admin, archived: :include, filters: [{:user, user}]}
        |> Recordings.list(1000)

      assert length(results) == 4
    end

    test "filters by visibility" do
      user = insert(:user)
      insert(:asciicast, user: user, visibility: :private)
      insert(:asciicast, user: user, visibility: :public)
      insert(:asciicast, user: user, visibility: :public)

      results =
        %Query{
          scope: :admin,
          archived: :include,
          filters: [{:user, user}, {:visibility, :public}]
        }
        |> Recordings.list(1000)

      assert length(results) == 2
    end

    test "filters by archived" do
      insert(:asciicast, archived_at: ~U[2024-12-01 00:00:00Z])
      insert(:asciicast, archived_at: nil)
      insert(:asciicast, archived_at: nil)

      assert length(Recordings.list(%Query{scope: :admin, archived: :only}, 1000)) == 1
    end

    test "filters by featured" do
      insert(:asciicast, featured: true)
      insert(:asciicast, featured: false)

      results =
        %Query{scope: :admin, archived: :include, filters: [{:featured, true}]}
        |> Recordings.list(1000)

      assert length(results) == 1
    end

    test "filters by user" do
      u = insert(:user)
      insert_list(2, :asciicast, user: u)
      insert(:asciicast)

      results =
        %Query{scope: :admin, archived: :include, filters: [{:user, u.id}]}
        |> Recordings.list(1000)

      assert length(results) == 2
    end

    test "search by title" do
      target = insert(:asciicast, title: "My Demo Recording")
      insert(:asciicast, title: "Unrelated")

      assert [%{id: id}] =
               %Query{scope: :admin, archived: :include, filters: [{:title, {:search, "demo"}}]}
               |> Recordings.list(10)

      assert id == target.id
    end

    test "filters by username" do
      u = insert(:user, username: "alicia")
      target = insert(:asciicast, user: u)
      insert(:asciicast)

      assert [%{id: id}] =
               %Query{scope: :admin, archived: :include, filters: [{:user, "alicia"}]}
               |> Recordings.list(10)

      assert id == target.id
    end

    test "respects limit" do
      insert_list(5, :asciicast)
      assert length(Recordings.list(%Query{scope: :admin, archived: :include}, 2)) == 2
    end

    test "orders by created desc" do
      first = insert(:asciicast)
      second = insert(:asciicast)
      third = insert(:asciicast)

      ids =
        %Query{scope: :admin, archived: :include, sort: {:created, :desc}}
        |> Recordings.list(3)
        |> Enum.map(& &1.id)
        |> Enum.filter(&(&1 in [first.id, second.id, third.id]))

      assert ids == [third.id, second.id, first.id]
    end

    test "sorts nullable sizes after known sizes" do
      user = insert(:user)
      unknown = insert(:asciicast, user: user, compressed_size: nil)
      small = insert(:asciicast, user: user, compressed_size: 100)
      large = insert(:asciicast, user: user, compressed_size: 200)

      ids =
        %Query{
          scope: :admin,
          archived: :include,
          filters: [{:user, user.id}],
          sort: {:size, :desc}
        }
        |> Recordings.list(3)
        |> Enum.map(& &1.id)

      assert ids == [large.id, small.id, unknown.id]
    end

    test "paginates in display order" do
      first = insert(:asciicast)
      second = insert(:asciicast)
      third = insert(:asciicast)

      page =
        %Query{scope: :admin, archived: :include, sort: {:created, :desc}}
        |> Recordings.paginate(1, 2)

      ids = Enum.map(page.entries, & &1.id)
      assert ids == [third.id, second.id]
      refute first.id in ids
    end
  end

  describe "unarchive/1" do
    test "clears archived_at and marks not archivable" do
      a = insert(:asciicast, archived_at: ~U[2020-01-01 00:00:00Z], archivable: true)

      {:ok, updated} = Recordings.unarchive(a)
      assert is_nil(updated.archived_at)
      assert updated.archivable == false
    end
  end

  describe "archive/1" do
    test "stamps archived_at" do
      a = insert(:asciicast, archived_at: nil)

      {:ok, archived} = Recordings.archive(a)
      assert %DateTime{} = archived.archived_at
    end
  end

  describe "count/1" do
    test "counts only recordings matching the spec (e.g. a user)" do
      user = insert(:user)
      other = insert(:user)
      insert_list(2, :asciicast, user: user)
      insert(:asciicast, user: other)

      assert Recordings.count(%Query{scope: :admin, archived: :include, filters: [user: user.id]}) ==
               2
    end
  end

  describe "byte_totals/1" do
    test "sums compressed and uncompressed sizes across the user's recordings" do
      u = insert(:user)
      insert(:asciicast, user: u, compressed_size: 100, uncompressed_size: 1000)
      insert(:asciicast, user: u, compressed_size: 250, uncompressed_size: 800)
      # other user's recording is excluded
      insert(:asciicast, compressed_size: 99_999, uncompressed_size: 99_999)

      assert Recordings.byte_totals(u.id) == {350, 1800}
    end

    test "returns {nil, nil} when the user has no recordings" do
      u = insert(:user)
      assert Recordings.byte_totals(u.id) == {nil, nil}
    end
  end

  describe "recordings_by_day/1" do
    test "returns exactly N entries" do
      assert length(Recordings.recordings_by_day(10)) == 10
    end

    test "buckets recordings into today" do
      base = Recordings.recordings_by_day(2) |> List.last() |> elem(1)
      insert_list(3, :asciicast)
      [{_today_date, today_count}] = Enum.take(Recordings.recordings_by_day(2), -1)
      assert today_count == base + 3
    end
  end
end
