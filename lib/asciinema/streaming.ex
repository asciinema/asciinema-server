defmodule Asciinema.Streaming do
  import Ecto.Changeset
  import Ecto.Query
  alias Asciinema.{Fonts, Repo, Themes}
  alias Asciinema.Streaming.{Query, Stream, StreamServer}
  alias Ecto.Changeset

  defdelegate recording_mode, to: StreamServer

  def find_live_stream_by_producer_token(token) do
    from(s in Stream, where: s.live and s.producer_token == ^token)
    |> Repo.one()
  end

  def get_stream(id) do
    Stream
    |> Repo.get(id)
    |> Repo.preload(:user)
  end

  def get_public_stream(id) do
    Stream
    |> Repo.get_by(id: id, visibility: :public)
    |> Repo.preload(:user)
  end

  def find_stream_by_public_token(token) do
    from(s in Stream, where: s.public_token == ^token)
    |> Repo.one()
    |> Repo.preload(:user)
  end

  def lookup_stream(id, allow_non_public_id \\ false) when is_binary(id) do
    cond do
      String.match?(id, ~r/^\d+$/) ->
        if allow_non_public_id do
          get_stream(id)
        else
          get_public_stream(id)
        end

      String.match?(id, ~r/^[[:alnum:]]{16}$/) ->
        find_stream_by_public_token(id)

      true ->
        nil
    end
  end

  def query(%Query{} = spec) do
    Stream
    |> apply_scope(spec.scope)
    |> apply_filters(spec.filters)
    |> sort(spec.sort)
  end

  defp apply_scope(query, :system), do: query
  defp apply_scope(query, :admin), do: query

  defp apply_scope(query, :public_listing),
    do: where(query, [s], s.visibility == :public)

  defp apply_scope(query, {:listing_for, nil}), do: apply_scope(query, :public_listing)

  defp apply_scope(query, {:listing_for, %{id: user_id}}),
    do: where(query, [s], s.visibility == :public or s.user_id == ^user_id)

  defp apply_filters(q, filters) when is_list(filters) do
    filters = Enum.uniq(filters)

    Enum.reduce(filters, q, &apply_filter/2)
  end

  defp apply_filters(q, filter), do: apply_filters(q, List.wrap(filter))

  defp apply_filter(filter, q) do
    case filter do
      {:id, {:not_eq, id}} ->
        where(q, [s], s.id != ^id)

      {:id, id} when is_integer(id) ->
        where(q, [s], s.id == ^id)

      {:user, %{id: user_id}} ->
        where(q, [s], s.user_id == ^user_id)

      {:user, user_id} when is_integer(user_id) ->
        where(q, [s], s.user_id == ^user_id)

      {:user, username} when is_binary(username) ->
        q
        |> ensure_user_join()
        |> where([user: u], fragment("lower(?)", u.username) == ^String.downcase(username))

      :public ->
        where(q, [s], s.visibility == :public)

      {:visibility, visibility} when visibility in [:public, :unlisted, :private] ->
        where(q, [s], s.visibility == ^visibility)

      :live ->
        where(q, [s], s.live)

      {:live, true} ->
        where(q, [s], s.live == true)

      {:live, false} ->
        where(q, [s], s.live == false)

      {:title, {:search, text}} ->
        search_title(q, text)

      {:token, token} ->
        where(q, [s], s.public_token == ^token)

      {:prefix, nil} ->
        q

      {:prefix, prefix} ->
        prefix = String.replace(prefix, "%", "")
        where(q, [s], like(s.public_token, ^"#{prefix}%"))

      :upcoming ->
        ten_min_ago = DateTime.shift(DateTime.utc_now(), minute: -10)
        where(q, [s], s.next_start_at > ^ten_min_ago and not s.live)

      :reschedulable ->
        now = DateTime.utc_now()
        where(q, [s], s.next_start_at < ^now)

      {:scheduled, true} ->
        where(q, [s], not is_nil(s.schedule))

      {:scheduled, false} ->
        where(q, [s], is_nil(s.schedule))

      {:audio, true} ->
        where(q, [s], not is_nil(s.audio_url))

      {:audio, false} ->
        where(q, [s], is_nil(s.audio_url))

      {:created_at, condition} ->
        apply_field_condition(q, :inserted_at, condition)

      {:last_started_at, :never} ->
        where(q, [s], is_nil(s.last_started_at))

      {:last_started_at, condition} ->
        apply_field_condition(q, :last_started_at, condition)

      {:current_viewer_count, condition} ->
        apply_field_condition(q, :current_viewer_count, condition)

      {:peak_viewer_count, condition} ->
        apply_field_condition(q, :peak_viewer_count, condition)

      {:recording_count, condition} ->
        q
        |> ensure_recording_counts_join()
        |> apply_count_condition(condition)
    end
  end

  defp sort(q, order) do
    case order do
      nil ->
        q

      :soonest ->
        order_by(q, asc_nulls_last: :next_start_at)

      :recently_started ->
        order_by(q, desc: :last_started_at)

      :activity ->
        order_by(q, desc: :live, desc_nulls_last: :last_started_at, desc: :id)

      :id ->
        order_by(q, asc: :id)

      {:created, :desc} ->
        order_by(q, [s], desc: s.inserted_at, desc: s.id)

      {:created, :asc} ->
        order_by(q, [s], asc: s.inserted_at, asc: s.id)

      {:last_started, :desc} ->
        order_by(q, [s], desc_nulls_last: s.last_started_at, desc: s.id)

      {:last_started, :asc} ->
        order_by(q, [s], asc_nulls_last: s.last_started_at, asc: s.id)

      {:current_viewers, :desc} ->
        order_by(q, [s], desc_nulls_last: s.current_viewer_count, desc: s.id)

      {:current_viewers, :asc} ->
        order_by(q, [s], asc_nulls_last: s.current_viewer_count, asc: s.id)

      {:peak_viewers, :desc} ->
        order_by(q, [s], desc_nulls_last: s.peak_viewer_count, desc: s.id)

      {:peak_viewers, :asc} ->
        order_by(q, [s], asc_nulls_last: s.peak_viewer_count, asc: s.id)
    end
  end

  defp apply_field_condition(q, field, {:eq, value}),
    do: where(q, [s], field(s, ^field) == ^value)

  defp apply_field_condition(q, field, {:gt, value}), do: where(q, [s], field(s, ^field) > ^value)

  defp apply_field_condition(q, field, {:gte, value}),
    do: where(q, [s], field(s, ^field) >= ^value)

  defp apply_field_condition(q, field, {:lt, value}), do: where(q, [s], field(s, ^field) < ^value)

  defp apply_field_condition(q, field, {:lte, value}),
    do: where(q, [s], field(s, ^field) <= ^value)

  defp apply_field_condition(q, field, {:between, from_value, to_value}),
    do: where(q, [s], field(s, ^field) >= ^from_value and field(s, ^field) <= ^to_value)

  defp ensure_user_join(q) do
    if has_named_binding?(q, :user) do
      q
    else
      join(q, :inner, [s], u in assoc(s, :user), as: :user)
    end
  end

  defp ensure_recording_counts_join(q) do
    if has_named_binding?(q, :recording_counts) do
      q
    else
      counts =
        from(a in Asciinema.Recordings.Asciicast,
          where: not is_nil(a.stream_id),
          group_by: a.stream_id,
          select: %{stream_id: a.stream_id, count: count(a.id)}
        )

      join(q, :left, [s], c in subquery(counts), on: c.stream_id == s.id, as: :recording_counts)
    end
  end

  defp apply_count_condition(q, {:eq, value}),
    do: where(q, [recording_counts: c], coalesce(c.count, 0) == ^value)

  defp apply_count_condition(q, {:gt, value}),
    do: where(q, [recording_counts: c], coalesce(c.count, 0) > ^value)

  defp apply_count_condition(q, {:gte, value}),
    do: where(q, [recording_counts: c], coalesce(c.count, 0) >= ^value)

  defp apply_count_condition(q, {:lt, value}),
    do: where(q, [recording_counts: c], coalesce(c.count, 0) < ^value)

  defp apply_count_condition(q, {:lte, value}),
    do: where(q, [recording_counts: c], coalesce(c.count, 0) <= ^value)

  defp apply_count_condition(q, {:between, from_value, to_value}),
    do:
      where(
        q,
        [recording_counts: c],
        coalesce(c.count, 0) >= ^from_value and coalesce(c.count, 0) <= ^to_value
      )

  defp search_title(q, text) do
    text
    |> String.split()
    |> Enum.reduce(q, fn term, q ->
      pattern = "%#{escape_like(term)}%"
      where(q, [s], ilike(s.title, ^pattern))
    end)
  end

  defp escape_like(term) do
    term
    |> String.replace("\\", "\\\\")
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
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
    |> maybe_preload(Keyword.get(opts, :preload, [:user]))
    |> Repo.paginate(paginate_opts)
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
          |> select([stream], stream.id)
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

  def cursor_paginate(query, last_id \\ nil, limit \\ 10)

  def cursor_paginate(%Query{} = spec, last_id, limit) do
    spec
    |> query()
    |> cursor_paginate(last_id, limit)
  end

  def cursor_paginate(%Ecto.Query{} = query, nil, limit) do
    do_cursor_paginate(query, limit)
  end

  def cursor_paginate(%Ecto.Query{} = query, last_id, limit) do
    query
    |> where([s], s.id > ^last_id)
    |> do_cursor_paginate(limit)
  end

  defp do_cursor_paginate(query, limit) do
    limit = min(limit, 100)

    query =
      query
      |> limit(^(limit + 1))
      |> maybe_preload([:user])

    entries = Repo.all(query)

    case entries do
      [] ->
        %{entries: [], has_more: false, last_id: nil}

      entries when length(entries) <= limit ->
        %{entries: entries, has_more: false, last_id: nil}

      entries ->
        {results, _} = Enum.split(entries, limit)
        last_id = List.last(results).id
        %{entries: results, has_more: true, last_id: last_id}
    end
  end

  def list(q, limit, opts \\ [])

  def list(%Query{} = spec, limit, opts) do
    spec
    |> query()
    |> list(limit, opts)
  end

  def list(q, nil, opts) do
    q
    |> maybe_preload(Keyword.get(opts, :preload, [:user]))
    |> Repo.all()
  end

  def list(q, limit, opts) when is_integer(limit) do
    q
    |> limit(^limit)
    |> maybe_preload(Keyword.get(opts, :preload, [:user]))
    |> Repo.all()
  end

  def count(%Query{} = spec), do: spec |> query() |> count()
  def count(q), do: Repo.count(q)

  @doc """
  Creates a new stream for the given user.

  Live stream limiting is enforced at the database level via a PostgreSQL trigger
  (`enforce_live_stream_limit`) to prevent race conditions during concurrent
  stream creation. The trigger locks the user row and counts existing live streams
  before allowing a new live stream to be created.
  """
  def create_stream(user, params \\ %{}) do
    %Stream{
      public_token: generate_public_token(),
      producer_token: generate_producer_token(),
      visibility: user.default_stream_visibility,
      term_theme_prefer_original: user.term_theme_prefer_original,
      term_bold_is_bright: user.term_bold_is_bright,
      term_adaptive_palette: user.term_adaptive_palette
    }
    |> change_stream(params)
    |> put_assoc(:user, user)
    |> Repo.insert()
    |> convert_live_limit_error(user.live_stream_limit)
  end

  defp convert_live_limit_error(result, live_stream_limit) do
    case result do
      {:ok, stream} ->
        {:ok, stream}

      {:error, %Changeset{errors: [{:live, _}]}} ->
        {:error, {:live_stream_limit_reached, live_stream_limit}}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @max_title_len 128
  @max_description_len 4096
  @max_term_type_len 64
  @max_term_version_len 255
  @max_shell_len 255
  @max_user_agent_len 255
  @max_audio_url_len 255

  def change_stream(stream, attrs \\ %{})

  def change_stream(stream, attrs) when is_map(attrs) do
    stream
    |> Repo.preload(:user)
    |> cast(attrs, [
      :audio_url,
      :buffer_time,
      :description,
      :env,
      :live,
      :shell,
      :term_font_family,
      :term_line_height,
      :term_theme_name,
      :term_theme_prefer_original,
      :term_bold_is_bright,
      :term_adaptive_palette,
      :term_type,
      :term_version,
      :title,
      :visibility,
      :schedule
    ])
    |> validate_schedule()
    |> validate_number(:buffer_time,
      greater_than_or_equal_to: 0.0,
      less_than_or_equal_to: 30.0
    )
    |> validate_inclusion(:term_theme_name, Themes.terminal_themes() ++ ["original"])
    |> validate_number(:term_line_height,
      greater_than_or_equal_to: 1.0,
      less_than_or_equal_to: 2.0
    )
    |> validate_inclusion(:term_font_family, Fonts.terminal_font_families())
    |> validate_length(:title, max: @max_title_len)
    |> validate_length(:description, max: @max_description_len)
    |> validate_length(:audio_url, max: @max_audio_url_len)
    |> validate_format(:audio_url, ~r|^https?://|)
    |> truncate(:term_type, @max_term_type_len)
    |> truncate(:term_version, @max_term_version_len)
    |> truncate(:shell, @max_shell_len)
    |> check_constraint(:live, name: "live_stream_limit")
  end

  defp truncate(changeset, field, max_len) do
    update_change(changeset, field, fn value ->
      if value, do: String.slice(value, 0, max_len)
    end)
  end

  def update_stream(stream, attrs) when is_list(attrs) do
    stream
    |> cast(Enum.into(attrs, %{}), Stream.__schema__(:fields))
    |> truncate(:user_agent, @max_user_agent_len)
    |> change_peak_viewer_count()
    |> change_last_activity()
    |> Repo.update!(returning: true)
  end

  @doc """
  Updates an existing stream with the given attributes.

  When setting `live: true`, the PostgreSQL trigger
  (`enforce_live_stream_limit`) will enforce the user's live stream limit to
  prevent race conditions. The trigger uses row-level locking to ensure
  atomicity during concurrent updates.
  """
  def update_stream(stream, attrs) when is_map(attrs) do
    stream
    |> change_stream(attrs)
    |> change_next_start_at()
    |> Repo.update()
    |> convert_live_limit_error(stream.user.live_stream_limit)
  end

  defp validate_schedule(changeset) do
    validate_change(changeset, :schedule, fn _, schedule ->
      try do
        get_next_start_at(schedule, user_timezone(changeset))

        []
      rescue
        # NOTE this may not be needed after upgrading crontab to >1.2.0
        RuntimeError ->
          [schedule: {"Invalid expression", []}]
      end
    end)
  end

  defp user_timezone(%Ecto.Changeset{} = changeset), do: user_timezone(changeset.data)
  defp user_timezone(%Stream{} = stream), do: stream.user.timezone || "Etc/UTC"

  defp change_peak_viewer_count(changeset) do
    case get_change(changeset, :current_viewer_count, :not_changed) do
      :not_changed ->
        changeset

      count ->
        peak_viewer_count = fetch_field!(changeset, :peak_viewer_count) || 0
        change(changeset, peak_viewer_count: max(count, peak_viewer_count))
    end
  end

  defp change_last_activity(changeset) do
    case fetch_field!(changeset, :live) do
      true ->
        change(changeset, %{last_activity_at: DateTime.utc_now(:second)})

      false ->
        changeset
    end
  end

  defp get_next_start_at(schedule, timezone) do
    schedule
    |> Crontab.Scheduler.get_next_run_dates(DateTime.now!(timezone))
    |> Elixir.Stream.take(1)
    |> Enum.to_list()
    |> List.first()
    |> maybe_map(&DateTime.shift_zone!(&1, "Etc/UTC"))
  end

  defp change_next_start_at(%Changeset{valid?: true} = changeset) do
    case get_change(changeset, :schedule, :not_changed) do
      :not_changed ->
        changeset

      nil ->
        change(changeset, next_start_at: nil)

      schedule ->
        timezone = user_timezone(changeset)

        change(changeset, next_start_at: get_next_start_at(schedule, timezone))
    end
  end

  defp change_next_start_at(%Changeset{valid?: false} = changeset), do: changeset

  def reschedule_streams do
    %Query{scope: :system, filters: [:reschedulable]}
    |> query()
    |> preload(:user)
    |> Repo.pages(100)
    |> Elixir.Stream.flat_map(& &1)
    |> Enum.each(&reschedule_stream/1)

    :ok
  end

  def reschedule_stream(stream) do
    if schedule = stream.schedule do
      timezone = user_timezone(stream)

      stream
      |> change(next_start_at: get_next_start_at(schedule, timezone))
      |> Repo.update!()
    else
      stream
    end
  end

  def delete_stream(stream), do: Repo.delete(stream)

  @doc """
  Attempts to stop the GenServer driving a live stream. Returns `:ok` on
  success, `{:error, :not_running}` if no server is registered for the stream.
  """
  def disconnect_stream(%Stream{id: id}) do
    try do
      StreamServer.stop(id, :shutdown)
      :ok
    catch
      :exit, {:noproc, _} -> {:error, :not_running}
      :exit, :noproc -> {:error, :not_running}
    end
  end

  def delete_streams(%{streams: _} = owner) do
    Repo.delete_all(Ecto.assoc(owner, :streams))

    :ok
  end

  def reassign_streams(src_user_id, dst_user_id) do
    from(s in Stream, where: s.user_id == ^src_user_id)
    |> Repo.update_all(set: [user_id: dst_user_id, updated_at: Timex.now()])
  end

  def mark_inactive_streams_offline do
    now = DateTime.utc_now()

    q =
      from(s in Stream,
        where:
          s.live and
            fragment(
              "COALESCE(last_activity_at, inserted_at) < ?::timestamp - make_interval(secs => offline_grace_period)",
              ^now
            )
      )

    {count, _} = Repo.update_all(q, set: [live: false, current_viewer_count: 0])

    count
  end

  defp generate_public_token, do: Crypto.random_token(16)
  defp generate_producer_token, do: Crypto.random_token(16)

  def short_public_token(stream), do: String.slice(stream.public_token, 0, 4)

  defp maybe_map(nil, _fun), do: nil
  defp maybe_map(value, fun) when is_function(fun, 1), do: fun.(value)
end
