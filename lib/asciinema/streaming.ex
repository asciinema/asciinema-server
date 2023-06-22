defmodule Asciinema.Streaming do
  alias Asciinema.Repo
  alias Asciinema.Streaming.LiveStream

  def find_live_stream_by_producer_token(token) do
    Repo.get_by(LiveStream, producer_token: token)
  end

  def get_live_stream(id) do
    Repo.get(LiveStream, id)
  end
end
