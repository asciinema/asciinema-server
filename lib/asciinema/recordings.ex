defmodule Asciinema.Recordings do
  require Logger
  import Ecto, only: [build_assoc: 2]
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Asciinema.Recordings.Asciicast.{V1, V2, V3}
  alias Asciinema.{FileCache, FileStore, Fonts, Fts, HttpUtil, Repo, Themes, Vt}
  alias Asciinema.Workers.{MigrateRecordingFiles, UpdateFtsContent, UpdateSnapshot}

  alias Asciinema.Recordings.{
    Asciicast,
    AsciicastStats,
    Markers,
    Paths,
    Text
  }

  alias Ecto.Changeset

  @secret_token_length 16
  @legacy_secret_token_length 25
  @secret_token_lengths [@secret_token_length, @legacy_secret_token_length]
  @secret_token_re ~r/^[[:alnum:]]+$/
  @search_work_mem "32MB"

  def get_asciicast(id, opts \\ []) do
    Asciicast
    |> maybe_load_snapshot(opts)
    |> Repo.get(id)
    |> Repo.preload([:user, :stats])
  end

  def get_public_asciicast(id, opts \\ []) do
    Asciicast
    |> maybe_load_snapshot(opts)
    |> Repo.get_by(id: id, visibility: :public)
    |> Repo.preload([:user, :stats])
  end

  def fetch_asciicast(id), do: OK.required(get_asciicast(id), :not_found)

  def find_asciicast_by_secret_token(token, opts \\ []) do
    from(a in Asciicast, where: a.secret_token == ^token)
    |> maybe_load_snapshot(opts)
    |> Repo.one()
    |> Repo.preload([:user, :stats])
  end

  def lookup_asciicast(id, opts \\ []) when is_binary(id) do
    cond do
      String.match?(id, ~r/^\d+$/) ->
        if Keyword.get(opts, :allow_non_public_id, false) do
          get_asciicast(id, opts)
        else
          get_public_asciicast(id, opts)
        end

      secret_token?(id) ->
        find_asciicast_by_secret_token(id, opts)

      true ->
        nil
    end
  end

  def fetch_cast_path(asciicast) do
    case FileStore.uri(asciicast.path) do
      "file://" <> path ->
        {:ok, path}

      "http" <> _rest = url ->
        FileCache.fetch_path(
          :cast,
          asciicast.id,
          fn tmp_dir ->
            path = Path.join(tmp_dir, "#{asciicast.id}.cast")
            :ok = HttpUtil.download_to(url, path, timeout: 30_000)

            path
          end,
          40_000
        )
    end
  end

  def get_cast_path!(asciicast) do
    case fetch_cast_path(asciicast) do
      {:ok, path} ->
        path

      {:error, error} ->
        raise error
    end
  end

  defp maybe_load_snapshot(query, opts) do
    if Keyword.get(opts, :load_snapshot, false) do
      select(query, [asciicast], %{asciicast | snapshot: asciicast.snapshot})
    else
      query
    end
  end

  def secret_token?(token) when is_binary(token) do
    String.match?(token, @secret_token_re) and byte_size(token) in @secret_token_lengths
  end

  def query(filters \\ [], order \\ nil)

  def query(filters, order) do
    filters =
      filters
      |> List.wrap()
      |> normalize_filters(order)

    needs_stats_join = Enum.member?(filters, :popular)

    from(Asciicast)
    |> where([a], is_nil(a.archived_at))
    |> maybe_join_stats(needs_stats_join)
    |> apply_filters(filters)
    |> sort(order)
  end

  defp apply_filters(q, filters) when is_list(filters) do
    filters = Enum.uniq(filters)

    Enum.reduce(filters, q, &apply_filter/2)
  end

  defp apply_filters(q, filter), do: apply_filters(q, List.wrap(filter))

  defp apply_filter(filter, q) do
    case filter do
      {:id, {:not_eq, id}} ->
        where(q, [a], a.id != ^id)

      {:user_id, user_id} ->
        where(q, [a], a.user_id == ^user_id)

      {:stream_id, stream_id} when is_integer(stream_id) ->
        where(q, [a], a.stream_id == ^stream_id)

      {:stream_id, {:not_eq, stream_id}} ->
        where(q, [a], is_nil(a.stream_id) or a.stream_id != ^stream_id)

      {:stream_id, {:in, stream_ids}} ->
        where(q, [a], a.stream_id in ^stream_ids)

      :featured ->
        where(q, [a], a.featured == true and a.visibility == :public)

      :popular ->
        where(
          q,
          [a, stats: s],
          a.visibility == :public and s.popularity_score > 0.0
        )

      :public ->
        where(q, [a], a.visibility == :public)

      :snapshotless ->
        where(q, [a], is_nil(a.snapshot))
    end
  end

  defp sort(q, nil), do: q

  defp sort(q, order) do
    case order do
      :date ->
        order_by(q, desc: :id)

      :popularity ->
        order_by(q, [a, stats: s],
          desc: s.popularity_score,
          desc: s.asciicast_id
        )

      :random ->
        order_by(q, fragment("RANDOM()"))
    end
  end

  defp maybe_join_stats(q, true) do
    join(q, :inner, [a], s in assoc(a, :stats), as: :stats)
  end

  defp maybe_join_stats(q, false), do: q

  defp normalize_filters(filters, :popularity), do: Enum.uniq([:popular | filters])
  defp normalize_filters(filters, _order), do: filters

  def search(%Ecto.Query{} = query, q) do
    from(a in query,
      join: f in "asciicast_fts",
      on: f.asciicast_id == a.id,
      where:
        fragment(
          "(? || ? || coalesce(?, ''::tsvector)) @@ websearch_to_tsquery('simple', ?)",
          f.title_tsv,
          f.description_tsv,
          f.content_tsv,
          ^q
        ),
      order_by:
        {:desc,
         fragment(
           "ts_rank_cd(setweight(?, 'A') || setweight(?, 'B') || setweight(coalesce(?, ''::tsvector), 'C'), websearch_to_tsquery('simple', ?), 4)",
           f.title_tsv,
           f.description_tsv,
           f.content_tsv,
           ^q
         )}
    )
  end

  def paginate(%Ecto.Query{} = query, page, page_size, opts \\ []) do
    paginate_opts =
      [page: page, page_size: page_size] ++ maybe_total_entries_opt(query, page_size, opts)

    query
    |> preload(:user)
    |> Repo.paginate(paginate_opts)
  end

  def search_paginate(%Ecto.Query{} = query, page, page_size, opts \\ []) do
    search_work_mem = Application.get_env(:asciinema, :search_work_mem, @search_work_mem)

    Repo.with_work_mem(search_work_mem, fn ->
      paginate(query, page, page_size, opts)
    end)
  end

  defp maybe_total_entries_opt(query, page_size, opts) do
    case opts[:max_pages] do
      nil ->
        []

      max_pages ->
        max_entries = page_size * max_pages
        limit = max_entries + 1

        limited_count =
          query
          |> exclude(:preload)
          |> exclude(:order_by)
          |> exclude(:select)
          |> select([asciicast], asciicast.id)
          |> limit(^limit)
          |> subquery()
          |> select([entry], count(entry.id))
          |> Repo.one()

        [options: [total_entries: min(limited_count || 0, max_entries)]]
    end
  end

  def list(q, limit) do
    q
    |> limit(^limit)
    |> preload(:user)
    |> Repo.all()
  end

  def stream(%Ecto.Query{} = query) do
    query
    |> preload(:user)
    |> Repo.pages(100)
    |> Stream.flat_map(& &1)
  end

  def count(q), do: Repo.count(q)

  def count_by(q, field) do
    from(a in q, group_by: field(a, ^field), select: {field(a, ^field), count(a.id)})
    |> Repo.all()
    |> Enum.into(%{})
  end

  def ensure_welcome_asciicast(user) do
    if Repo.count(Ecto.assoc(user, :asciicasts)) == 0 do
      cast_path = Path.join(:code.priv_dir(:asciinema), "welcome.cast")

      upload = %Plug.Upload{
        path: cast_path,
        filename: "ascii.cast",
        content_type: "application/octet-stream"
      }

      {:ok, _} =
        create_asciicast(user, upload, %{
          visibility: :public,
          snapshot_at: 106.0
        })
    end

    :ok
  end

  def create_asciicast(
        user,
        %Plug.Upload{filename: filename} = upload,
        # defaults and private fields
        safe_fields \\ %{},
        # user provided fields
        unsafe_fields \\ %{}
      ) do
    attrs =
      Map.merge(
        %{
          filename: filename,
          visibility: user.default_recording_visibility,
          secret_token: generate_secret_token(),
          term_bold_is_bright: user.term_bold_is_bright,
          term_adaptive_palette: user.term_adaptive_palette
        },
        safe_fields
      )

    changeset =
      user
      |> build_assoc(:asciicasts)
      |> change(attrs)

    with {:ok, metadata} <- extract_metadata(upload),
         changeset = apply_metadata(changeset, metadata, user),
         changeset = change_asciicast(changeset, unsafe_fields),
         {:ok, %Asciicast{} = asciicast} <- do_create_asciicast(changeset, upload) do
      if asciicast.snapshot == nil do
        %{asciicast_id: asciicast.id}
        |> UpdateSnapshot.new()
        |> Oban.insert!()
      end

      %{asciicast_id: asciicast.id}
      |> UpdateFtsContent.new()
      |> Oban.insert!()

      {:ok, asciicast}
    end
  end

  defp extract_metadata(%Plug.Upload{path: path}) do
    case V2.fetch_metadata(path) do
      {:ok, metadata} -> {:ok, metadata}
      {:error, {:invalid_version, 3}} -> V3.fetch_metadata(path)
      {:error, {:invalid_version, _} = reason} -> {:error, reason}
      {:error, :invalid_format} -> V1.fetch_metadata(path)
    end
  end

  @max_title_len 128
  @max_description_len 4096
  @max_term_type_len 64
  @max_term_version_len 255
  @max_shell_len 255
  @max_command_len 255
  @max_user_agent_len 255
  @max_audio_url_len 255
  @max_term_cols 720
  @max_term_rows 200
  @hex_color_re ~r/^#[0-9a-f]{6}$/
  @hex_palette_re ~r/^(#[0-9a-f]{6}:){7}((#[0-9a-f]{6}:){8})?#[0-9a-f]{6}$/

  defp apply_metadata(changeset, metadata, user) do
    term_theme_name =
      if metadata[:term_theme_palette] && user.term_theme_prefer_original, do: "original"

    changeset
    |> put_change(:version, metadata.version)
    |> put_change(:term_theme_name, term_theme_name)
    |> cast(metadata, [
      :duration,
      :term_cols,
      :term_rows,
      :term_type,
      :term_version,
      :term_theme_fg,
      :term_theme_bg,
      :term_theme_palette,
      :command,
      :shell,
      :uname,
      :recorded_at,
      :env,
      :idle_time_limit,
      :title
    ])
    |> validate_required([:duration, :term_cols, :term_rows])
    |> validate_number(:term_cols, greater_than: 0, less_than_or_equal_to: @max_term_cols)
    |> validate_number(:term_rows, greater_than: 0, less_than_or_equal_to: @max_term_rows)
    |> validate_format(:term_theme_fg, @hex_color_re)
    |> validate_format(:term_theme_bg, @hex_color_re)
    |> validate_format(:term_theme_palette, @hex_palette_re)
    |> validate_change(:env, &validate_env/2)
    |> truncate(:term_type, @max_term_type_len)
    |> truncate(:term_version, @max_term_version_len)
    |> truncate(:command, @max_command_len)
    |> truncate(:shell, @max_shell_len)
    |> truncate(:title, @max_title_len)
    |> truncate(:user_agent, @max_user_agent_len)
  end

  defp validate_env(:env, env) do
    errors = []

    errors =
      if Enum.all?(Map.keys(env), &String.match?(&1, ~r/^[A-Z0-9_]+$/)) do
        errors
      else
        [{:env, "must include valid env var names"} | errors]
      end

    errors =
      if Enum.all?(Map.values(env), &is_binary/1) do
        errors
      else
        [{:env, "must include only string values"} | errors]
      end

    errors
  end

  defp truncate(changeset, field, max_len) do
    update_change(changeset, field, fn value ->
      if value, do: String.slice(value, 0, max_len)
    end)
  end

  defp do_create_asciicast(changeset, file) do
    Repo.transact(fn ->
      with {:ok, asciicast} <- Repo.insert(changeset) do
        asciicast = assign_path(asciicast)
        save_file(asciicast.path, file)

        {:ok, asciicast}
      end
    end)
  end

  def assign_path(asciicast) do
    asciicast = Repo.preload(asciicast, :user)
    path = Paths.path(asciicast)

    asciicast
    |> Changeset.change(path: path)
    |> Repo.update!()
  end

  defp save_file(path, %{path: tmp_path, content_type: content_type}) do
    :ok = FileStore.put_file(path, tmp_path, content_type)
  end

  def change_asciicast(asciicast, attrs \\ %{}) do
    asciicast
    |> cast(attrs, [
      :visibility,
      :title,
      :description,
      :term_cols_override,
      :term_rows_override,
      :term_theme_name,
      :term_bold_is_bright,
      :term_adaptive_palette,
      :term_line_height,
      :term_font_family,
      :idle_time_limit,
      :speed,
      :snapshot_at,
      :markers,
      :audio_url
    ])
    |> validate_length(:title, max: @max_title_len)
    |> validate_length(:description, max: @max_description_len)
    |> validate_length(:audio_url, max: @max_audio_url_len)
    |> validate_format(:audio_url, ~r|^https?://|)
    |> validate_number(:term_cols_override,
      greater_than: 0,
      less_than_or_equal_to: @max_term_cols
    )
    |> validate_number(:term_rows_override,
      greater_than: 0,
      less_than_or_equal_to: @max_term_rows
    )
    |> validate_number(:idle_time_limit, greater_than_or_equal_to: 0.5)
    |> validate_inclusion(:term_theme_name, Themes.terminal_themes() ++ ["original"])
    |> validate_number(:term_line_height,
      greater_than_or_equal_to: 1.0,
      less_than_or_equal_to: 2.0
    )
    |> validate_inclusion(:term_font_family, Fonts.terminal_font_families())
    |> validate_number(:snapshot_at, greater_than: 0)
    |> validate_change(:markers, &Markers.validate/2)
  end

  def update_asciicast(asciicast, attrs \\ %{}) do
    changeset = change_asciicast(asciicast, attrs)

    with {:ok, asciicast} <- Repo.update(changeset) do
      if stale_snapshot?(changeset) do
        update_snapshot(asciicast)
      else
        {:ok, asciicast}
      end
    end
  end

  defp stale_snapshot?(changeset) do
    changed?(changeset, :snapshot_at) ||
      changed?(changeset, :term_cols_override) ||
      changed?(changeset, :term_rows_override)
  end

  def set_featured(asciicast, featured \\ true) do
    asciicast
    |> Changeset.change(%{featured: featured})
    |> Repo.update!()
  end

  def delete_asciicast(asciicast) do
    with {:ok, asciicast} <- Repo.delete(asciicast) do
      case FileStore.delete_file(asciicast.path) do
        :ok -> {:ok, asciicast}
        {:error, :enoent} -> {:ok, asciicast}
        otherwise -> otherwise
      end
    end
  end

  def delete_asciicasts(%{asciicasts: _} = owner) do
    delete_asciicasts(Ecto.assoc(owner, :asciicasts))
  end

  def delete_asciicasts(%Ecto.Query{} = query) do
    asciicasts = Repo.all(query)

    Enum.each(asciicasts, fn a ->
      {:ok, _} = delete_asciicast(a)
    end)

    length(asciicasts)
  end

  def update_snapshot(%Asciicast{} = asciicast) do
    cols = asciicast.term_cols_override || asciicast.term_cols
    rows = asciicast.term_rows_override || asciicast.term_rows
    secs = asciicast.snapshot_at || asciicast.duration / 2

    snapshot =
      asciicast
      |> event_stream()
      |> output()
      |> generate_snapshot(cols, rows, secs)

    asciicast
    |> Changeset.cast(%{snapshot: snapshot}, [:snapshot])
    |> Repo.update()
  end

  def generate_snapshot(output_stream, cols, rows, secs) do
    {:ok, vt} = Vt.new(cols, rows, 0)

    output_stream
    |> Stream.take_while(&frame_before_or_at?(&1, secs))
    |> Enum.each(fn {_, text} -> Vt.feed(vt, text) end)

    Vt.dump_screen(vt)
  end

  def update_fts_content(%Asciicast{} = asciicast) do
    cols = asciicast.term_cols_override || asciicast.term_cols
    rows = asciicast.term_rows_override || asciicast.term_rows

    content =
      asciicast
      |> event_stream()
      |> generate_fts_content(cols, rows)

    set_content_tsv(asciicast.id, content)
  end

  defp set_content_tsv(id, content, attempt \\ 1) do
    try do
      Repo.update_all(
        from(f in "asciicast_fts",
          where: f.asciicast_id == ^id,
          update: [set: [content_tsv: fragment("to_tsvector('simple', ?)", ^content)]]
        ),
        []
      )

      :ok
    rescue
      e in Postgrex.Error ->
        if e.postgres.code == :program_limit_exceeded do
          if attempt < 10 do
            content = String.slice(content, 0, div(String.length(content) * 9, 10))
            set_content_tsv(id, content, attempt + 1)
          else
            {:error, :too_long}
          end
        else
          reraise e, __STACKTRACE__
        end
    end
  end

  def generate_fts_content(events, cols, rows) do
    {:ok, fts} = Fts.new(cols, rows)

    events
    |> Stream.each(fn {_, code, data} ->
      case code do
        "o" ->
          Fts.feed(fts, data)

        "r" ->
          {cols, rows} = data
          Fts.resize(fts, cols, rows)

        _ ->
          :ok
      end
    end)
    |> Stream.run()

    Fts.dump(fts)
  end

  def event_stream(%Asciicast{} = asciicast) do
    path = get_cast_path!(asciicast)

    case asciicast.version do
      1 -> V1.event_stream(path)
      2 -> V2.event_stream(path)
      3 -> V3.event_stream(path)
    end
  end

  def output(stream) do
    stream
    |> Stream.filter(fn {_, code, _} -> code == "o" end)
    |> Stream.map(fn {time, _, data} -> {time, data} end)
  end

  def title(asciicast) do
    cond do
      asciicast.title not in [nil, ""] ->
        asciicast.title

      asciicast.command not in [nil, ""] && asciicast.command != asciicast.shell ->
        asciicast.command

      true ->
        "untitled"
    end
  end

  defdelegate text(asciicast), to: Text

  defp frame_before_or_at?({time, _}, secs) do
    time <= secs
  end

  @popularity_half_life_days 7
  @popularity_window_days 90

  def recompute_popularity_scores(scope \\ :all) do
    cutoff = Date.add(Date.utc_today(), -@popularity_window_days)

    decay_scores =
      from dv in "asciicast_daily_views",
        where: dv.date >= ^cutoff,
        group_by: dv.asciicast_id,
        select: %{
          asciicast_id: dv.asciicast_id,
          decay_score:
            fragment(
              "sum(? * power(0.5, (CURRENT_DATE - ?)::float / ?))",
              dv.count,
              dv.date,
              ^@popularity_half_life_days
            )
        }

    case scope do
      :all ->
        ids_with_views =
          from(dv in "asciicast_daily_views",
            where: dv.date >= ^cutoff,
            distinct: true,
            select: dv.asciicast_id
          )

        Repo.transact(
          fn ->
            # Update stats for asciicasts with daily views in the window.
            {count, _} =
              from(s in AsciicastStats,
                join: a in Asciicast,
                on: a.id == s.asciicast_id,
                join: ds in subquery(decay_scores),
                on: ds.asciicast_id == s.asciicast_id,
                where: is_nil(a.archived_at),
                update: [set: [popularity_score: ds.decay_score, popularity_dirty: false]]
              )
              |> Repo.update_all([])

            # Reset scores for non-archived stats without views in the window.
            Repo.update_all(
              from(s in AsciicastStats,
                join: a in Asciicast,
                on: a.id == s.asciicast_id,
                where:
                  is_nil(a.archived_at) and s.asciicast_id not in subquery(ids_with_views) and
                    (s.popularity_score > 0.0 or s.popularity_dirty == true)
              ),
              set: [popularity_score: 0.0, popularity_dirty: false]
            )

            {:ok, count}
          end,
          # 5 min
          timeout: 5 * 60 * 1000
        )

      :dirty ->
        dirty_ids =
          from(s in AsciicastStats,
            join: a in Asciicast,
            on: a.id == s.asciicast_id,
            where: s.popularity_dirty == true and is_nil(a.archived_at),
            select: s.asciicast_id
          )

        decay_scores = from(dv in decay_scores, where: dv.asciicast_id in subquery(dirty_ids))

        Repo.transact(
          fn ->
            # Update dirty stats for asciicasts that have daily views in the window.
            {count, _} =
              from(s in AsciicastStats,
                join: ds in subquery(decay_scores),
                on: ds.asciicast_id == s.asciicast_id,
                where: s.asciicast_id in subquery(dirty_ids),
                update: [
                  set: [
                    popularity_score: ds.decay_score,
                    popularity_dirty: false
                  ]
                ]
              )
              |> Repo.update_all([])

            # Clear remaining dirty stats with no daily views.
            Repo.update_all(
              from(s in AsciicastStats, where: s.asciicast_id in subquery(dirty_ids)),
              set: [popularity_score: 0.0, popularity_dirty: false]
            )

            {:ok, count}
          end,
          # 5 min
          timeout: 5 * 60 * 1000
        )
    end
  end

  def register_view(asciicast, date \\ Date.utc_today()) do
    Repo.transact(fn ->
      Repo.insert_all(
        AsciicastStats,
        [
          %{
            asciicast_id: asciicast.id,
            popularity_score: 0.0,
            total_views: 1,
            popularity_dirty: true
          }
        ],
        on_conflict: [inc: [total_views: 1], set: [popularity_dirty: true]],
        conflict_target: [:asciicast_id]
      )

      Repo.insert_all(
        "asciicast_daily_views",
        [%{asciicast_id: asciicast.id, date: date, count: 1}],
        on_conflict: [inc: [count: 1]],
        conflict_target: [:asciicast_id, :date]
      )

      {:ok, :ok}
    end)
  end

  def migratable(stream), do: Stream.filter(stream, &stale_path?/1)

  defp stale_path?(asciicast) do
    asciicast.path != Paths.path(asciicast)
  end

  def migrate_files(user) do
    %{user_id: user.id}
    |> MigrateRecordingFiles.new()
    |> Oban.insert!()

    :ok
  end

  def migrate_file(id) when is_integer(id) do
    id
    |> get_asciicast()
    |> migrate_file()
  end

  def migrate_file(asciicast) do
    cur_path = asciicast.path
    new_path = Paths.path(asciicast)

    if cur_path != new_path do
      changeset = change(asciicast, path: new_path)

      {:ok, asciicast} =
        Repo.transact(fn ->
          asciicast = Repo.update!(changeset)
          :ok = FileStore.move_file(cur_path, new_path)

          {:ok, asciicast}
        end)

      asciicast
    else
      asciicast
    end
  end

  def hide_unclaimed_asciicasts(tmp_users_query, t) do
    query =
      from a in Asciicast,
        join: u in ^tmp_users_query,
        on: a.user_id == u.id,
        where: a.archivable and is_nil(a.archived_at) and a.inserted_at < ^t

    {count, _} = Repo.update_all(query, set: [archived_at: Timex.now()])

    count
  end

  def delete_unclaimed_asciicasts(tmp_users_query, t) do
    query =
      from a in Asciicast,
        join: u in ^tmp_users_query,
        on: a.user_id == u.id,
        where: a.archivable and a.inserted_at < ^t

    delete_asciicasts(query)
  end

  def reassign_asciicasts(src_user_id, dst_user_id) do
    q = from(a in Asciicast, where: a.user_id == ^src_user_id)
    Repo.update_all(q, set: [user_id: dst_user_id, updated_at: Timex.now()])
  end

  defp generate_secret_token, do: Crypto.random_token(@secret_token_length)

  # View count token - valid for 24 hours
  @view_count_token_max_age 3600 * 24

  def generate_view_count_token(asciicast_id) do
    Phoenix.Token.sign(AsciinemaWeb.Endpoint, "view-count", asciicast_id)
  end

  def verify_view_count_token(token) do
    Phoenix.Token.verify(AsciinemaWeb.Endpoint, "view-count", token,
      max_age: @view_count_token_max_age
    )
  end
end
