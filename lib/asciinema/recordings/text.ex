defmodule Asciinema.Recordings.Text do
  alias Asciinema.Recordings.{Asciicast, Output, Paths}
  alias Asciinema.{FileCache, Vt}

  def text(%Asciicast{cols: cols, rows: rows} = asciicast) do
    output = Output.stream(asciicast)

    Vt.with_vt(cols, rows, [resizable: true, scrollback_limit: nil], fn vt ->
      Enum.each(output, fn {_, text} -> Vt.feed(vt, text) end)

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
