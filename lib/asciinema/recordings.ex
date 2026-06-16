defmodule Asciinema.Recordings do
  require Logger
  import Ecto, only: [build_assoc: 2]
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Asciinema.Asciicast.Reader
  alias Asciinema.Asciicast.{V1, V2, V3}
  alias Asciinema.{FileCache, FileStore, Fonts, Fts, HttpUtil, Repo, Themes, Vt, Zstd}
  alias Asciinema.Workers.{MigrateRecordingFiles, UpdateFtsContent, UpdateSnapshot}

  alias Asciinema.Recordings.{
    Asciicast,
    AsciicastStats,
    Markers,
    Paths,
    Query,
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

  def get_asciicast!(id, opts \\ []) do
    Asciicast
    |> maybe_load_snapshot(opts)
    |> Repo.get!(id)
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
    bucket = cast_cache_bucket(asciicast.compressed)

    case FileStore.uri(asciicast.path) do
      "file://" <> path ->
        {:ok, path}

      "http" <> _rest = url ->
        FileCache.fetch_path(
          bucket,
          asciicast.id,
          fn tmp_dir ->
            path = Path.join(tmp_dir, to_string(asciicast.id))

            :ok =
              HttpUtil.download_to(url, path,
                timeout: 30_000,
                decompress: false
              )

            path
          end,
          40_000
        )
    end
  end

  def cast_cache_bucket(true), do: :cast_zst
  def cast_cache_bucket(false), do: :cast

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

  def query(%Query{} = spec) do
    Asciicast
    |> apply_scope(spec.scope)
    |> apply_archived(spec.archived)
    |> apply_filters(spec.filters)
    |> sort(spec.sort, spec.filters)
  end

  defp apply_scope(query, :system), do: query
  defp apply_scope(query, :admin), do: query

  defp apply_scope(query, :public_listing),
    do: where(query, [a], a.visibility == :public)

  defp apply_scope(query, {:listing_for, nil}), do: apply_scope(query, :public_listing)

  defp apply_scope(query, {:listing_for, %{id: user_id}}),
    do: where(query, [a], a.visibility == :public or a.user_id == ^user_id)

  defp apply_archived(query, :exclude), do: where(query, [a], is_nil(a.archived_at))
  defp apply_archived(query, :include), do: query
  defp apply_archived(query, :only), do: where(query, [a], not is_nil(a.archived_at))

  defp apply_filters(q, filters) when is_list(filters) do
    filters
    |> Enum.uniq()
    |> Enum.reduce(q, &apply_filter/2)
  end

  defp apply_filters(q, filter), do: apply_filters(q, List.wrap(filter))

  defp apply_filter(filter, q) do
    case filter do
      {:id, {:not_eq, id}} ->
        where(q, [a], a.id != ^id)

      {:id, id} when is_integer(id) ->
        where(q, [a], a.id == ^id)

      {:user, %{id: user_id}} ->
        where(q, [a], a.user_id == ^user_id)

      {:user, user_id} when is_integer(user_id) ->
        where(q, [a], a.user_id == ^user_id)

      {:user, username} when is_binary(username) ->
        q
        |> ensure_user_join()
        |> where([user: u], fragment("lower(?)", u.username) == ^String.downcase(username))

      {:stream, %{id: stream_id}} ->
        where(q, [a], a.stream_id == ^stream_id)

      {:stream, stream_id} when is_integer(stream_id) ->
        where(q, [a], a.stream_id == ^stream_id)

      {:stream, true} ->
        where(q, [a], not is_nil(a.stream_id))

      {:stream, false} ->
        where(q, [a], is_nil(a.stream_id))

      {:stream, {:not_eq, stream_id}} ->
        where(q, [a], is_nil(a.stream_id) or a.stream_id != ^stream_id)

      {:stream, {:in, stream_ids}} ->
        where(q, [a], a.stream_id in ^stream_ids)

      {:full_text, {:search, text}} ->
        q
        |> ensure_fts_join()
        |> where(
          [fts: f],
          fragment(
            "(? || ? || coalesce(?, ''::tsvector)) @@ websearch_to_tsquery('simple', ?)",
            f.title_tsv,
            f.description_tsv,
            f.content_tsv,
            ^text
          )
        )

      {:title, {:search, text}} ->
        q
        |> ensure_fts_join()
        |> where([fts: f], fragment("? @@ websearch_to_tsquery('simple', ?)", f.title_tsv, ^text))

      {:token, token} ->
        where(q, [a], a.secret_token == ^token)

      :featured ->
        where(q, [a], a.featured == true)

      {:featured, true} ->
        where(q, [a], a.featured == true)

      {:featured, false} ->
        where(q, [a], a.featured != true or is_nil(a.featured))

      :popular ->
        q
        |> ensure_stats_inner_join()
        |> where([_a, stats_inner: s], s.popularity_score > 0.0)

      :public ->
        where(q, [a], a.visibility == :public)

      {:visibility, visibility} when visibility in [:public, :unlisted, :private] ->
        where(q, [a], a.visibility == ^visibility)

      {:created_at, condition} ->
        apply_field_condition(q, :inserted_at, condition)

      {:duration, condition} ->
        apply_field_condition(q, :duration, condition)

      {:compressed_size, condition} ->
        apply_field_condition(q, :compressed_size, condition)

      {:views, condition} ->
        q
        |> with_total_views()
        |> apply_views_condition(condition)

      {:audio, true} ->
        where(q, [a], not is_nil(a.audio_url))

      {:audio, false} ->
        where(q, [a], is_nil(a.audio_url))

      :snapshotless ->
        where(q, [a], is_nil(a.snapshot))
    end
  end

  defp sort(q, nil, _filters), do: q
  defp sort(q, :random, _filters), do: order_by(q, fragment("RANDOM()"))
  defp sort(q, {:created, :desc}, _filters), do: order_by(q, [a], desc: a.inserted_at, desc: a.id)
  defp sort(q, {:created, :asc}, _filters), do: order_by(q, [a], asc: a.inserted_at, asc: a.id)

  # duration is NOT NULL, so plain asc/desc lets one btree serve both directions
  defp sort(q, {:duration, :desc}, _filters),
    do: order_by(q, [a], desc: a.duration, desc: a.id)

  defp sort(q, {:duration, :asc}, _filters),
    do: order_by(q, [a], asc: a.duration, asc: a.id)

  defp sort(q, {:size, :desc}, _filters),
    do: order_by(q, [a], desc_nulls_last: a.compressed_size, desc: a.id)

  defp sort(q, {:size, :asc}, _filters),
    do: order_by(q, [a], asc_nulls_last: a.compressed_size, asc: a.id)

  defp sort(q, {:views, dir}, _filters) when dir in [:asc, :desc] do
    q
    |> with_total_views()
    |> order_by([a, stats_left: s], [{^dir, coalesce(s.total_views, 0)}, {^dir, a.id}])
  end

  defp sort(q, {:popularity, :desc}, _filters) do
    q
    |> ensure_stats_inner_join()
    |> order_by([a, stats_inner: s], desc: s.popularity_score, desc: s.asciicast_id)
  end

  defp sort(q, {:rank, :desc}, filters) do
    case search_filter(filters) do
      {:full_text, text} ->
        q
        |> ensure_fts_join()
        |> order_by([fts: f],
          desc:
            fragment(
              "ts_rank_cd(setweight(?, 'A') || setweight(?, 'B') || setweight(coalesce(?, ''::tsvector), 'C'), websearch_to_tsquery('simple', ?), 4)",
              f.title_tsv,
              f.description_tsv,
              f.content_tsv,
              ^text
            )
        )

      {:title, text} ->
        q
        |> ensure_fts_join()
        |> order_by([fts: f],
          desc:
            fragment(
              "ts_rank_cd(setweight(?, 'A'), websearch_to_tsquery('simple', ?), 4)",
              f.title_tsv,
              ^text
            )
        )

      nil ->
        raise ArgumentError, "rank sort requires a supported search filter"
    end
  end

  defp ensure_stats_inner_join(q) do
    if has_named_binding?(q, :stats_inner) do
      q
    else
      join(q, :inner, [a], s in assoc(a, :stats), as: :stats_inner)
    end
  end

  defp ensure_stats_left_join(q) do
    if has_named_binding?(q, :stats_left) do
      q
    else
      join(q, :left, [a], s in assoc(a, :stats), as: :stats_left)
    end
  end

  defp with_total_views(q) do
    q
    |> ensure_stats_left_join()
    |> select_merge([stats_left: s], %{total_views: coalesce(s.total_views, 0)})
  end

  defp apply_field_condition(q, field, {:eq, value}),
    do: where(q, [a], field(a, ^field) == ^value)

  defp apply_field_condition(q, field, {:gt, value}), do: where(q, [a], field(a, ^field) > ^value)

  defp apply_field_condition(q, field, {:gte, value}),
    do: where(q, [a], field(a, ^field) >= ^value)

  defp apply_field_condition(q, field, {:lt, value}), do: where(q, [a], field(a, ^field) < ^value)

  defp apply_field_condition(q, field, {:lte, value}),
    do: where(q, [a], field(a, ^field) <= ^value)

  defp apply_field_condition(q, field, {:between, from_value, to_value}),
    do: where(q, [a], field(a, ^field) >= ^from_value and field(a, ^field) <= ^to_value)

  defp apply_views_condition(q, {:eq, value}),
    do: where(q, [stats_left: s], coalesce(s.total_views, 0) == ^value)

  defp apply_views_condition(q, {:gt, value}),
    do: where(q, [stats_left: s], coalesce(s.total_views, 0) > ^value)

  defp apply_views_condition(q, {:gte, value}),
    do: where(q, [stats_left: s], coalesce(s.total_views, 0) >= ^value)

  defp apply_views_condition(q, {:lt, value}),
    do: where(q, [stats_left: s], coalesce(s.total_views, 0) < ^value)

  defp apply_views_condition(q, {:lte, value}),
    do: where(q, [stats_left: s], coalesce(s.total_views, 0) <= ^value)

  defp apply_views_condition(q, {:between, from_value, to_value}) do
    where(
      q,
      [stats_left: s],
      coalesce(s.total_views, 0) >= ^from_value and coalesce(s.total_views, 0) <= ^to_value
    )
  end

  defp ensure_fts_join(q) do
    if has_named_binding?(q, :fts) do
      q
    else
      join(q, :inner, [a], f in "asciicast_fts", on: f.asciicast_id == a.id, as: :fts)
    end
  end

  defp ensure_user_join(q) do
    if has_named_binding?(q, :user) do
      q
    else
      join(q, :inner, [a], u in assoc(a, :user), as: :user)
    end
  end

  defp search_filter(filters) do
    Enum.find_value(filters, fn
      {:full_text, {:search, text}} -> {:full_text, text}
      {:title, {:search, text}} -> {:title, text}
      _ -> nil
    end)
  end

  def paginate(query, page, page_size, opts \\ [])

  def paginate(%Query{} = spec, page, page_size, opts) do
    spec
    |> query()
    |> paginate(page, page_size, opts)
  end

  def paginate(%Ecto.Query{} = query, page, page_size, opts) do
    paginate_opts =
      [page: page, page_size: page_size] ++ maybe_total_entries_opt(query, page_size, opts)

    query
    |> maybe_with_total_views(Keyword.get(opts, :with_total_views, false))
    |> maybe_preload(Keyword.get(opts, :preload, [:user]))
    |> Repo.paginate(paginate_opts)
  end

  def search_paginate(query, page, page_size, opts \\ [])

  def search_paginate(%Query{} = spec, page, page_size, opts) do
    spec
    |> query()
    |> search_paginate(page, page_size, opts)
  end

  def search_paginate(%Ecto.Query{} = query, page, page_size, opts) do
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

  defp maybe_preload(query, []), do: query
  defp maybe_preload(query, nil), do: query
  defp maybe_preload(query, preloads), do: preload(query, ^preloads)

  def list(q, limit, opts \\ [])

  def list(%Query{} = spec, limit, opts) do
    spec
    |> query()
    |> list(limit, opts)
  end

  def list(q, limit, opts) do
    q
    |> maybe_with_total_views(Keyword.get(opts, :with_total_views, false))
    |> limit(^limit)
    |> maybe_preload(Keyword.get(opts, :preload, [:user]))
    |> Repo.all()
  end

  defp maybe_with_total_views(q, true), do: with_total_views(q)
  defp maybe_with_total_views(q, false), do: q

  def stream(%Query{} = spec) do
    spec
    |> query()
    |> stream()
  end

  def stream(%Ecto.Query{} = query) do
    query
    |> maybe_preload([:user])
    |> Repo.pages(100)
    |> Stream.flat_map(& &1)
  end

  def uncompressed_asciicast_ids_stream do
    from(a in Asciicast,
      where: a.compressed == false,
      select: %{id: a.id}
    )
    |> Repo.pages(1000)
    |> Stream.flat_map(& &1)
    |> Stream.map(& &1.id)
  end

  def count(%Query{} = spec), do: spec |> query() |> count()
  def count(q), do: Repo.count(q)

  @doc """
  Total number of recordings owned by the user (including archived ones).
  """
  def count_user_asciicasts(user), do: Repo.count(Ecto.assoc(user, :asciicasts))

  @doc """
  Returns `{compressed_total, uncompressed_total}` bytes summed across the
  user's recordings. Either side is `nil` when no recording has that size set.
  """
  def byte_totals(user_id) do
    Repo.one(
      from(a in Asciicast,
        where: a.user_id == ^user_id,
        select: {sum(a.compressed_size), sum(a.uncompressed_size)}
      )
    )
  end

  @doc "List of `{Date, count}` of new recordings per day over the last `days` days, oldest first."
  def recordings_by_day(days) when is_integer(days) and days > 0 do
    today = Date.utc_today()
    start_date = Date.add(today, -(days - 1))
    cutoff = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")

    rows =
      from(a in Asciicast,
        where: a.inserted_at >= ^cutoff,
        group_by: fragment("date_trunc('day', ?)::date", a.inserted_at),
        select: {fragment("date_trunc('day', ?)::date", a.inserted_at), count()}
      )
      |> Repo.all()
      |> Map.new()

    start_date
    |> Date.range(today)
    |> Enum.map(fn d -> {d, Map.get(rows, d, 0)} end)
  end

  def count_by(%Query{} = spec, field), do: spec |> query() |> count_by(field)

  def count_by(q, :stream) do
    count_by(q, :stream_id)
  end

  def count_by(q, field) do
    from(a in q, group_by: field(a, ^field), select: {field(a, ^field), count(a.id)})
    |> Repo.all()
    |> Enum.into(%{})
  end

  def create_asciicast(user, local_path, attrs \\ %{}, params \\ %{})
      when is_binary(local_path) do
    with {:ok, metadata} <- extract_metadata(local_path),
         metadata = Map.put(metadata, :filename, normalize_filename(params)),
         changeset = build_asciicast(user, attrs, metadata, params),
         :ok <- validate_asciicast(changeset),
         {compressed_path, changeset} = compress_file(local_path, changeset),
         {store_path, changeset} = assign_store_path(changeset),
         :ok <- save_file(compressed_path, store_path),
         {:ok, asciicast} <- insert_asciicast_or_delete_file(changeset, store_path),
         :ok <- schedule_bg_jobs(asciicast) do
      {:ok, asciicast}
    end
  end

  defp build_asciicast(user, attrs, metadata, params) do
    defaults = %{
      visibility: user.default_recording_visibility,
      secret_token: generate_secret_token(),
      term_bold_is_bright: user.term_bold_is_bright,
      term_adaptive_palette: user.term_adaptive_palette,
      term_theme_name: term_theme_name(user, metadata)
    }

    {version, metadata} = Map.pop!(metadata, :version)
    {filename, metadata} = Map.pop!(metadata, :filename)
    {duration, metadata} = Map.pop!(metadata, :duration)

    attrs =
      Map.merge(attrs, %{
        version: version,
        filename: filename,
        duration: duration
      })

    user
    |> build_assoc(:asciicasts)
    |> change(defaults)
    |> change(attrs)
    |> foreign_key_constraint(:stream_id)
    |> apply_metadata(metadata)
    |> change_asciicast(params)
  end

  defp validate_asciicast(%Changeset{valid?: true}), do: :ok
  defp validate_asciicast(%Changeset{valid?: false} = changeset), do: {:error, changeset}

  defp compress_file(input_path, changeset) do
    output_path = Zstd.compress_file(input_path, compression_level: 9)

    changeset =
      change(changeset, %{
        uncompressed_size: file_size(input_path),
        compressed_size: file_size(output_path),
        compressed: true
      })

    {output_path, changeset}
  end

  defp assign_store_path(changeset) do
    # Paths.path/1 needs id and inserted_at so we have to prepare them here
    changeset =
      if Changeset.get_field(changeset, :id) != nil do
        changeset
      else
        change(changeset,
          id: get_next_asciicast_id(),
          inserted_at: DateTime.truncate(DateTime.utc_now(), :second)
        )
      end

    asciicast =
      changeset
      |> Changeset.apply_changes()
      |> Repo.preload(:user, force: true)

    path = Paths.path(asciicast)
    changeset = change(changeset, path: path)

    {path, changeset}
  end

  defp save_file(local_path, store_path) do
    FileStore.put_file(store_path, local_path, "application/x-asciicast")
  end

  defp get_next_asciicast_id do
    [[id]] = Repo.query!("SELECT nextval('asciicasts_id_seq')").rows

    id
  end

  defp insert_asciicast_or_delete_file(changeset, store_path) do
    try do
      case Repo.insert(changeset) do
        {:ok, asciicast} ->
          {:ok, asciicast}

        {:error, changeset} ->
          maybe_delete_file(store_path)
          {:error, changeset}
      end
    rescue
      error ->
        maybe_delete_file(store_path)
        reraise error, __STACKTRACE__
    end
  end

  defp schedule_bg_jobs(asciicast) do
    if asciicast.snapshot == nil do
      schedule_snapshot_update(asciicast.id)
    end

    schedule_fts_content_update(asciicast.id)

    :ok
  end

  defp term_theme_name(user, metadata) do
    if metadata[:term_theme_palette] && user.term_theme_prefer_original do
      "original"
    end
  end

  defp file_size(path) do
    File.stat!(path).size
  end

  defp extract_metadata(path) when is_binary(path) do
    if Reader.compressed?(path) do
      {:error, :invalid_format}
    else
      case V2.fetch_metadata(path) do
        {:ok, metadata} -> {:ok, metadata}
        {:error, {:invalid_version, 3}} -> V3.fetch_metadata(path)
        {:error, {:invalid_version, _} = reason} -> {:error, reason}
        {:error, :invalid_format} -> V1.fetch_metadata(path)
      end
    end
  end

  @max_filename_len 255

  defp normalize_filename(params) do
    case params["filename"] || params[:filename] do
      filename when is_binary(filename) ->
        filename
        |> Path.basename()
        |> String.slice(0, @max_filename_len)

      _ ->
        "asciicast.cast"
    end
  end

  @allowed_metadata [
    :term_cols,
    :term_rows,
    :term_type,
    :term_version,
    :term_theme_fg,
    :term_theme_bg,
    :term_theme_palette,
    :command,
    :shell,
    :recorded_at,
    :env,
    :idle_time_limit,
    :title
  ]

  @max_title_len 128
  @max_description_len 4096
  @max_term_type_len 64
  @max_term_version_len 255
  @max_shell_len 255
  @max_command_len 255
  @max_audio_url_len 255
  @max_term_cols 720
  @max_term_rows 200
  @hex_color_re ~r/^#[0-9a-f]{6}$/
  @hex_palette_re ~r/^(#[0-9a-f]{6}:){7}((#[0-9a-f]{6}:){8})?#[0-9a-f]{6}$/

  defp apply_metadata(changeset, metadata) do
    changeset
    |> cast(metadata, @allowed_metadata)
    |> validate_required([:term_cols, :term_rows])
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

  defp schedule_snapshot_update(asciicast_id) do
    %{asciicast_id: asciicast_id}
    |> UpdateSnapshot.new()
    |> Oban.insert!()
  end

  defp schedule_fts_content_update(asciicast_id) do
    %{asciicast_id: asciicast_id}
    |> UpdateFtsContent.new()
    |> Oban.insert!()
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
    |> validate_number(:idle_time_limit, greater_than: 0.0)
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
    |> Repo.update()
  end

  def archive(asciicast) do
    asciicast
    |> Changeset.change(%{archived_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  @doc """
  Reverses an archive: clears `archived_at` and marks the recording not
  archivable, so the auto-archiver won't immediately archive it again.
  """
  def unarchive(asciicast) do
    asciicast
    |> Changeset.change(%{archived_at: nil, archivable: false})
    |> Repo.update()
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

  def compress_asciicast(%Asciicast{compressed: true} = asciicast), do: {:ok, asciicast}

  def compress_asciicast(%Asciicast{} = asciicast) do
    asciicast = Repo.preload(asciicast, :user)
    old_store_path = asciicast.path
    source_path = get_cast_path!(asciicast)
    {zst_path, changeset} = compress_file(source_path, asciicast)
    {new_store_path, changeset} = assign_store_path(changeset)
    :ok = save_file(zst_path, new_store_path)
    _ = File.rm(zst_path)

    try do
      asciicast = Repo.update!(changeset)
      maybe_delete_file(old_store_path)

      {:ok, asciicast}
    rescue
      error ->
        maybe_delete_file(new_store_path)
        reraise error, __STACKTRACE__
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
    opts = [compressed: asciicast.compressed]

    case asciicast.version do
      1 -> V1.event_stream(path, opts)
      2 -> V2.event_stream(path, opts)
      3 -> V3.event_stream(path, opts)
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

  defp maybe_delete_file(path) do
    case FileStore.delete_file(path) do
      :ok ->
        :ok

      {:error, :enoent} ->
        :ok

      {:error, reason} ->
        Logger.warning("failed to delete file #{path}: #{inspect(reason)}")
        :ok
    end
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
