defmodule Asciinema.Streaming do
  import Ecto.Changeset
  alias Asciinema.Repo
  alias Asciinema.Streaming.LiveStream
  alias Ecto.Query

  def find_live_stream_by_producer_token(token) do
    Repo.get_by(LiveStream, producer_token: token)
  end

  def get_live_stream(id) when is_integer(id) or is_binary(id) do
    Repo.get(LiveStream, id)
  end

  def get_live_stream(owner) do
    owner
    |> Ecto.assoc(:live_streams)
    |> Query.first()
    |> Repo.one()
  end

  def create_live_stream!(user) do
    %LiveStream{}
    |> change(producer_token: generate_producer_token())
    |> put_assoc(:user, user)
    |> Repo.insert!()
  end

  def touch(stream) do
    stream
    |> cast(%{last_activity_at: Timex.now()}, [:last_activity_at])
    |> Repo.update!()
  end

  defp generate_producer_token, do: Crypto.random_token(25)
end
