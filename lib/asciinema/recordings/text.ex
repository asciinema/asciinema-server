defmodule Asciinema.Recordings.Text do
  alias Asciinema.Recordings.{Asciicast, EventStream, Paths}
  alias Asciinema.{FileCache, Vt}

  def text(%Asciicast{cols: cols, rows: rows} = asciicast) do
    stream = EventStream.new(asciicast)

    Vt.with_vt(cols, rows, [scrollback_limit: nil], fn vt ->
      Enum.each(stream, fn {_, code, data} ->
        case code do
          "o" ->
            Vt.feed(vt, data)

          "r" ->
            [cols, rows] = String.split(data, "x")
            cols = String.to_integer(cols)
            rows = String.to_integer(rows)
            Vt.resize(vt, cols, rows)

          _ ->
            :ok
        end
      end)

      Vt.text(vt)
    end)
  end

  def text_file_path(asciicast) do
    FileCache.full_path(
      :txt,
      Paths.sharded_path(asciicast, ".txt"),
      fn -> text(asciicast) end
    )
  end
end
