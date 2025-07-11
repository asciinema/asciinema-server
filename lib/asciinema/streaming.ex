defmodule Asciinema.Streaming do
  import Ecto.Changeset
  import Ecto.Query
  alias Asciinema.{Fonts, Repo}
  alias Asciinema.Streaming.{Stream, StreamServer}

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

  def find_stream_by_public_token(token) do
    from(s in Stream, where: s.public_token == ^token)
    |> Repo.one()
    |> Repo.preload(:user)
  end

  def lookup_stream(id) when is_binary(id) do
    cond do
      String.match?(id, ~r/^\d+$/) ->
        get_stream(id)

      String.match?(id, ~r/^[[:alnum:]]{16}$/) ->
        find_stream_by_public_token(id)

      true ->
        nil
    end
  end

  # TODO: remove after release of the final CLI 3.0
  def find_user_stream_by_public_token(%{streams: _} = owner, prefix) do
    prefix = String.replace(prefix, "%", "")

    owner
    |> Ecto.assoc(:streams)
    |> where([s], like(s.public_token, ^"#{prefix}%"))
    |> first()
    |> Repo.one()
    |> Repo.preload(:user)
  end

  def query(filters \\ [], order \\ nil) do
    from(Stream)
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
        where(q, [s], s.id != ^id)

      {:user_id, user_id} ->
        where(q, [s], s.user_id == ^user_id)

      :live ->
        where(q, [s], s.live)

      {:prefix, nil} ->
        q

      {:prefix, prefix} ->
        prefix = String.replace(prefix, "%", "")
        where(q, [s], like(s.public_token, ^"#{prefix}%"))
    end
  end

  defp sort(q, order) do
    case order do
      nil ->
        q

      :activity ->
        order_by(q, desc: :live, desc_nulls_last: :last_started_at, desc: :id)

      :id ->
        order_by(q, asc: :id)
    end
  end

  def paginate(%Ecto.Query{} = query, page, page_size) do
    query
    |> preload(:user)
    |> Repo.paginate(page: page, page_size: page_size)
  end

  def cursor_paginate(query, last_id \\ nil, limit \\ 10)

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
      |> preload(:user)

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

  def list(q, limit \\ nil)

  def list(q, nil) do
    q
    |> preload(:user)
    |> Repo.all()
  end

  def list(q, limit) do
    q
    |> limit(^limit)
    |> preload(:user)
    |> Repo.all()
  end

  def create_stream(user, params \\ %{}) do
    %Stream{}
    |> change(
      public_token: generate_public_token(),
      producer_token: generate_producer_token(),
      visibility: user.default_stream_visibility,
      term_theme_prefer_original: user.term_theme_prefer_original
    )
    |> put_assoc(:user, user)
    |> change_stream(params)
    |> Repo.insert()
  end

  def change_stream(stream, attrs \\ %{})

  def change_stream(stream, attrs) when is_map(attrs) do
    stream
    |> cast(attrs, [
      :live,
      :title,
      :description,
      :visibility,
      :term_theme_name,
      :term_theme_prefer_original,
      :buffer_time,
      :term_line_height,
      :term_font_family,
      :audio_url
    ])
    |> validate_number(:buffer_time,
      greater_than_or_equal_to: 0.0,
      less_than_or_equal_to: 30.0
    )
    |> validate_number(:term_line_height,
      greater_than_or_equal_to: 1.0,
      less_than_or_equal_to: 2.0
    )
    |> validate_inclusion(:term_font_family, Fonts.terminal_font_families())
    |> validate_format(:audio_url, ~r|^https?://|)
    |> check_constraint(:live, name: "live_stream_limit")
  end

  def update_stream(stream, attrs) when is_list(attrs) do
    stream
    |> cast(Enum.into(attrs, %{}), Stream.__schema__(:fields))
    |> update_peak_viewer_count()
    |> change_last_activity()
    |> Repo.update!()
  end

  def update_stream(stream, attrs) when is_map(attrs) do
    stream
    |> change_stream(attrs)
    |> Repo.update()
  end

  defp update_peak_viewer_count(changeset) do
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
        cast(changeset, %{last_activity_at: Timex.now()}, [:last_activity_at])

      false ->
        changeset
    end
  end

  def delete_stream(stream), do: Repo.delete(stream)

  def delete_streams(%{streams: _} = owner) do
    Repo.delete_all(Ecto.assoc(owner, :streams))

    :ok
  end

  def reassign_streams(src_user_id, dst_user_id) do
    from(s in Stream, where: s.user_id == ^src_user_id)
    |> Repo.update_all(set: [user_id: dst_user_id, updated_at: Timex.now()])
  end

  def mark_inactive_streams_offline do
    t = Timex.shift(Timex.now(), minutes: -1)

    q =
      from(s in Stream,
        where: s.live and fragment("COALESCE(last_activity_at, inserted_at) < ?", ^t)
      )

    {count, _} = Repo.update_all(q, set: [live: false, current_viewer_count: 0])

    count
  end

  defp generate_public_token, do: Crypto.random_token(16)
  defp generate_producer_token, do: Crypto.random_token(16)

  def short_public_token(stream), do: String.slice(stream.public_token, 0, 4)
end
