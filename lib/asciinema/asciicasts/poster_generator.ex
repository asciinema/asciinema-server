defmodule Asciinema.Asciicasts.PosterGenerator do
  alias Asciinema.Asciicast

  @doc "Generates poster for given asciicast"
  @callback generate(asciicast :: %Asciicast{}) :: :ok | {:error, term}

  def generate(asciicast) do
    Application.get_env(:asciinema, :poster_generator).generate(asciicast)
  end
end
