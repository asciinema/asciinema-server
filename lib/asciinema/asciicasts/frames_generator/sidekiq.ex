defmodule Asciinema.Asciicasts.FramesGenerator.Sidekiq do
  alias Asciinema.Asciicasts.Asciicast
  alias Asciinema.SidekiqClient

  def generate_frames(%Asciicast{id: id}) do
    SidekiqClient.enqueue("AsciicastWorker", [id])
  end
end
