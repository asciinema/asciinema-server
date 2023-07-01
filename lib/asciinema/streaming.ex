defmodule Asciinema.Streaming do
  import Ecto.Changeset
  import Ecto.Query
  alias Asciinema.Repo
  alias Asciinema.Streaming.LiveStream

  def find_live_stream_by_producer_token(token) do
    Repo.get_by(LiveStream, producer_token: token)
  end

  def get_live_stream(id) when is_integer(id) or is_binary(id) do
    LiveStream
    |> Repo.get(id)
    |> Repo.preload(:user)
  end

  def get_live_stream(owner) do
    owner
    |> Ecto.assoc(:live_streams)
    |> first()
    |> Repo.one()
  end

  def create_live_stream!(user) do
    %LiveStream{}
    |> change(producer_token: generate_producer_token())
    |> put_assoc(:user, user)
    |> Repo.insert!()
  end

  def update_live_stream(stream, attrs) when is_list(attrs) do
    stream
    |> change(attrs)
    |> change_last_activity()
    |> Repo.update!()
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
end
