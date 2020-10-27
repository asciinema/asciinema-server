defmodule Asciinema.PngGenerator do
  alias Asciinema.Asciicasts.Asciicast

  @doc "Generates PNG image from asciicast and returns path to it"
  @callback generate(asciicast :: %Asciicast{}) :: {:ok, String.t()} | {:error, term}

  def generate(asciicast) do
    Application.get_env(:asciinema, :png_generator).generate(asciicast)
  end
end
