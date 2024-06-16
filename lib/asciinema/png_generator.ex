defmodule Asciinema.PngGenerator do
  alias Asciinema.Recordings.Asciicast

  @doc "Generates PNG image from asciicast and returns path to it"
  @callback generate(asciicast :: %Asciicast{}) :: {:ok, String.t()} | {:error, term}

  def generate(asciicast) do
    Keyword.fetch!(Application.get_env(:asciinema, __MODULE__), :adapter).generate(asciicast)
  end
end
