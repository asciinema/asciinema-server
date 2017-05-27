defmodule Asciinema.PngGenerator do
  alias Asciinema.Asciicast
  alias Asciinema.PngGenerator.PngParams

  @doc "Generates PNG image from asciicast and returns path to it"
  @callback generate(asciicast :: %Asciicast{}, png_params :: %PngParams{}) :: {:ok, String.t} | {:error, term}

  def generate(asciicast, png_params) do
    Application.get_env(:asciinema, :png_generator).generate(asciicast, png_params)
  end
end
