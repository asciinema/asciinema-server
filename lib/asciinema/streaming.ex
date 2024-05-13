defmodule Asciinema.Streaming do
  import Ecto.Changeset
  import Ecto.Query
  alias Asciinema.{Fonts, Repo}
  alias Asciinema.Streaming.LiveStream

  def find_live_stream_by_producer_token(token) do
    Repo.get_by(LiveStream, producer_token: token)
  end

  def get_live_stream(id) when is_integer(id) do
    LiveStream
    |> Repo.get(id)
    |> Repo.preload(:user)
  end

  def get_live_stream(id) when is_binary(id) do
    stream =
      if String.match?(id, ~r/[[:alpha:]]/) do
        Repo.one(from(s in LiveStream, where: s.public_token == ^id))
      end

    Repo.preload(stream, :user)
  end

  def get_live_stream(%{live_streams: _} = owner, nil) do
    owner
    |> Ecto.assoc(:live_streams)
    |> first()
    |> Repo.one()
  end

  def get_live_stream(%{live_streams: _} = owner, id) do
    owner
    |> Ecto.assoc(:live_streams)
    |> where([s], like(s.public_token, ^"#{id}%"))
    |> first()
    |> Repo.one()
  end

  def fetch_live_stream(id) do
    case get_live_stream(id) do
      nil -> {:error, :not_found}
      stream -> {:ok, stream}
    end
  end

  def list_public_live_streams(owner, limit \\ 4) do
    owner
    |> live_streams_q(limit)
    |> where([s], s.visibility == :public)
    |> Repo.all()
  end

  def list_all_live_streams(owner, limit \\ 4) do
    owner
    |> live_streams_q(limit)
    |> Repo.all()
  end

  defp live_streams_q(%{live_streams: _} = owner, limit) do
    owner
    |> Ecto.assoc(:live_streams)
    |> where([s], s.online)
    |> order_by(desc: :last_started_at)
    |> limit(^limit)
    |> preload(:user)
  end

  def create_live_stream!(user) do
    %LiveStream{}
    |> change(
      public_token: generate_public_token(),
      producer_token: generate_producer_token(),
      theme_prefer_original: user.theme_prefer_original
    )
    |> put_assoc(:user, user)
    |> Repo.insert!()
  end

  def change_live_stream(stream, attrs \\ %{})

  def change_live_stream(stream, attrs) when is_map(attrs) do
    stream
    |> cast(attrs, [
      :title,
      :description,
      :visibility,
      :theme_name,
      :theme_prefer_original,
      :buffer_time,
      :terminal_line_height,
      :terminal_font_family
    ])
    |> validate_number(:buffer_time,
      greater_than_or_equal_to: 0.0,
      less_than_or_equal_to: 30.0
    )
    |> validate_number(:terminal_line_height,
      greater_than_or_equal_to: 1.0,
      less_than_or_equal_to: 2.0
    )
    |> validate_inclusion(:terminal_font_family, Fonts.terminal_font_families())
  end

  def update_live_stream(stream, attrs) when is_list(attrs) do
    stream
    |> cast(Enum.into(attrs, %{}), LiveStream.__schema__(:fields))
    |> update_peak_viewer_count()
    |> change_last_activity()
    |> Repo.update!()
  end

  def update_live_stream(stream, attrs) when is_map(attrs) do
    stream
    |> change_live_stream(attrs)
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

  def delete_live_streams(%{live_streams: _} = owner) do
    Repo.delete_all(Ecto.assoc(owner, :live_streams))

    :ok
  end

  def reassign_live_streams(src_user_id, dst_user_id) do
    from(s in LiveStream, where: s.user_id == ^src_user_id)
    |> Repo.update_all(set: [user_id: dst_user_id, updated_at: Timex.now()])
  end

  def mark_inactive_live_streams_offline do
    t = Timex.shift(Timex.now(), minutes: -1)
    q = from(s in LiveStream, where: s.online and s.last_activity_at < ^t)

    {count, _} = Repo.update_all(q, set: [online: false])

    count
  end

  defp generate_public_token, do: Crypto.random_token(16)
  defp generate_producer_token, do: Crypto.random_token(16)
end
