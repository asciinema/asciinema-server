defmodule Asciinema.Asciicasts.FramesGenerator do
  alias Asciinema.Asciicast

  @doc "Generates frames file for given asciicast"
  @callback generate_frames(asciicast :: %Asciicast{}) :: :ok | {:error, term}

  def generate_frames(asciicast) do
    Application.get_env(:asciinema, :frames_generator).generate_frames(asciicast)
  end
end
