defmodule Asciinema.Asciicasts.PosterGenerator.Sidekiq do
  alias Asciinema.Asciicast
  alias Asciinema.SidekiqClient

  def generate(%Asciicast{id: id}) do
    SidekiqClient.enqueue("AsciicastWorker", [id])
  end
end
