defmodule Asciinema.Recordings.Text do
  alias Asciinema.Recordings
  alias Asciinema.Recordings.{Asciicast, Paths}
  alias Asciinema.{FileCache, Vt}

  def text(%Asciicast{term_cols: cols, term_rows: rows} = asciicast) do
    {:ok, vt} = Vt.new(cols, rows, nil)

    asciicast
    |> Recordings.event_stream()
    |> Enum.each(fn {_, code, data} ->
      case code do
        "o" ->
          Vt.feed(vt, data)

        "r" ->
          {cols, rows} = data
          Vt.resize(vt, cols, rows)

        _ ->
          :ok
      end
    end)

    Vt.text(vt)
  end

  def text_file_path(asciicast) do
    FileCache.full_path(
      :txt,
      Paths.path(asciicast, "txt"),
      fn -> text(asciicast) end
    )
  end
end
