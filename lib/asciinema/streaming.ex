defmodule Asciinema.Streaming do
  import Ecto.Changeset
  import Ecto.Query
  alias Asciinema.{Media, Repo}
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
      cond do
        String.match?(id, ~r/[[:alpha:]]/) ->
          Repo.one(from(s in LiveStream, where: s.secret_token == ^id))

        String.match?(id, ~r/^\d+$/) ->
          id = String.to_integer(id)
          Repo.one(from(s in LiveStream, where: s.private == false and s.id == ^id))

        true ->
          nil
      end

    Repo.preload(stream, :user)
  end

  def get_live_stream(%{live_streams: _} = owner) do
    owner
    |> Ecto.assoc(:live_streams)
    |> first()
    |> Repo.one()
  end

  def fetch_live_stream(id) do
    case get_live_stream(id) do
      nil -> {:error, :not_found}
      stream -> {:ok, stream}
    end
  end

  def create_live_stream!(user) do
    %LiveStream{}
    |> change(secret_token: generate_secret_token(), producer_token: generate_producer_token())
    |> put_assoc(:user, user)
    |> Repo.insert!()
  end

  def change_live_stream(stream, attrs \\ %{})

  def change_live_stream(stream, attrs) when is_map(attrs) do
    stream
    |> cast(attrs, [
      :title,
      :description,
      :private,
      :theme_name,
      :terminal_line_height,
      :terminal_font_family
    ])
    |> validate_number(:terminal_line_height,
      greater_than_or_equal_to: 1.0,
      less_than_or_equal_to: 2.0
    )
    |> validate_inclusion(:terminal_font_family, Media.custom_terminal_font_families())
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

  defp generate_producer_token, do: Crypto.random_token(25)
  defp generate_secret_token, do: Crypto.random_token(25)
end
