defmodule Asciinema.Streaming do
  import Ecto.Changeset
  import Ecto.Query
  alias Asciinema.{Fonts, Repo}
  alias Asciinema.Streaming.{Stream, StreamServer}

  defdelegate recording_mode, to: StreamServer

  def find_stream_by_producer_token(token) do
    Repo.get_by(Stream, producer_token: token)
  end

  def get_stream(id) when is_integer(id) do
    Stream
    |> Repo.get(id)
    |> Repo.preload(:user)
  end

  def get_stream(id) when is_binary(id) do
    stream =
      if String.match?(id, ~r/[[:alpha:]]/) do
        Repo.one(from(s in Stream, where: s.public_token == ^id))
      end

    Repo.preload(stream, :user)
  end

  def get_stream(%{streams: _} = owner, id) do
    owner
    |> Ecto.assoc(:streams)
    |> where([s], like(s.public_token, ^"#{id}%"))
    |> first()
    |> Repo.one()
  end

  def fetch_stream(owner, id), do: wrap(get_stream(owner, id))

  def fetch_default_stream(%{streams: _} = owner) do
    streams =
      owner
      |> Ecto.assoc(:streams)
      |> limit(2)
      |> Repo.all()

    case streams do
      [] -> {:error, :not_found}
      [stream] -> {:ok, stream}
      _ -> {:error, :too_many}
    end
  end

  defp wrap(nil), do: {:error, :not_found}
  defp wrap(value), do: {:ok, value}

  def query(filters \\ []) do
    from(Stream)
    |> order_by(desc: :last_started_at)
    |> apply_filters(filters)
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
        where(q, [s], s.online)
    end
  end

  def list(q, limit) do
    q
    |> limit(^limit)
    |> preload(:user)
    |> Repo.all()
  end

  def create_stream!(user) do
    %Stream{}
    |> change(
      public_token: generate_public_token(),
      producer_token: generate_producer_token(),
      visibility: user.default_stream_visibility,
      term_theme_prefer_original: user.term_theme_prefer_original
    )
    |> put_assoc(:user, user)
    |> Repo.insert!()
  end

  def create_stream(user) do
    if user.stream_limit == nil or count_streams(user) < user.stream_limit do
      {:ok, create_stream!(user)}
    else
      {:error, :limit_reached}
    end
  end

  defp count_streams(user), do: Repo.count(Ecto.assoc(user, :streams))

  def change_stream(stream, attrs \\ %{})

  def change_stream(stream, attrs) when is_map(attrs) do
    stream
    |> cast(attrs, [
      :title,
      :description,
      :visibility,
      :term_theme_name,
      :term_theme_prefer_original,
      :buffer_time,
      :term_line_height,
      :term_font_family
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
    case fetch_field!(changeset, :online) do
      true ->
        cast(changeset, %{last_activity_at: Timex.now()}, [:last_activity_at])

      false ->
        changeset
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
    t = Timex.shift(Timex.now(), minutes: -1)
    q = from(s in Stream, where: s.online and s.last_activity_at < ^t)

    {count, _} = Repo.update_all(q, set: [online: false])

    count
  end

  defp generate_public_token, do: Crypto.random_token(16)
  defp generate_producer_token, do: Crypto.random_token(16)
end
