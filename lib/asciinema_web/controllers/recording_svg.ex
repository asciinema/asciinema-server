defmodule AsciinemaWeb.RecordingSVG do
  use Phoenix.View,
    root: "lib/asciinema_web/controllers/recording",
    path: "",
    pattern: "**/*.svg",
    namespace: AsciinemaWeb

  import AsciinemaWeb.RecordingHTML, only: [cols: 1, rows: 1]
  import Phoenix.HTML
  alias Asciinema.Media
  alias Asciinema.Recordings.Snapshot

  def text_class(%{} = attrs) do
    classes =
      attrs
      |> Enum.reject(fn {attr, _} -> attr == "bg" end)
      |> Enum.map(&text_class/1)
      |> Enum.filter(& &1)

    case classes do
      [] -> nil
      _ -> Enum.join(classes, " ")
    end
  end

  def text_class({"fg", fg}) when is_integer(fg), do: "c-#{fg}"
  def text_class({"bold", true}), do: "br"
  def text_class({"faint", true}), do: "fa"
  def text_class({"italic", true}), do: "it"
  def text_class({"underline", true}), do: "un"
  def text_class(_), do: nil

  def rect_style(%{"bg" => [_r, _g, _b] = c}), do: "fill:#{hex(c)}"
  def rect_style(%{"bg" => "rgb(" <> _ = c}), do: "fill:#{c}"
  def rect_style(_), do: nil

  def rect_class(%{"bg" => bg}) when is_integer(bg), do: "c-#{bg}"
  def rect_class(_), do: nil

  def text_style(%{"fg" => [_r, _g, _b] = c}), do: "fill:#{hex(c)}"
  def text_style(%{"fg" => "rgb(" <> _ = c}), do: "fill:#{c}"
  def text_style(_), do: nil

  defp hex([r, g, b]) do
    "##{hex(r)}#{hex(g)}#{hex(b)}"
  end

  defp hex(int) do
    int
    |> Integer.to_string(16)
    |> String.pad_leading(2, "0")
  end

  def percent(float) do
    "#{Decimal.round(Decimal.from_float(float), 3)}%"
  end

  def show(%{asciicast: asciicast} = assigns) do
    snapshot = Snapshot.new(asciicast.snapshot)
    bg_lines = Snapshot.coords(snapshot)

    text_lines =
      snapshot
      |> Snapshot.regroup(:cells)
      |> Snapshot.coords()
      |> remove_blank_segments()

    render(
      "terminal.svg",
      cols: cols(asciicast),
      rows: rows(asciicast),
      bg_lines: bg_lines,
      text_lines: text_lines,
      rx: assigns[:rx],
      ry: assigns[:ry],
      font_family: assigns[:font_family],
      theme_name: Media.theme_name(asciicast)
    )
  end

  defp remove_blank_segments(lines) do
    for line <- lines do
      segments = Enum.reject(line.segments, &(String.trim(&1.text) == ""))
      %{line | segments: segments}
    end
  end
end
