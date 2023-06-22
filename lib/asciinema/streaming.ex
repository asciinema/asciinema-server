defmodule Asciinema.Streaming do
  import Ecto.Changeset
  alias Asciinema.Repo
  alias Asciinema.Streaming.LiveStream

  def find_live_stream_by_producer_token(token) do
    Repo.get_by(LiveStream, producer_token: token)
  end

  def get_live_stream(id) do
    Repo.get(LiveStream, id)
  end

  def create_live_stream!(user) do
    %LiveStream{}
    |> change(producer_token: generate_producer_token())
    |> put_assoc(:user, user)
    |> Repo.insert!()
  end

  defp generate_producer_token, do: Crypto.random_token(25)
end
