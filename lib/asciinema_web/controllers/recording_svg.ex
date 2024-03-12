defmodule AsciinemaWeb.RecordingSVG do
  use Phoenix.View,
    root: "lib/asciinema_web/controllers/recording",
    path: "",
    pattern: "**/*.svg",
    namespace: AsciinemaWeb

  import AsciinemaWeb.RecordingHTML, only: [adjust_colors: 1, cols: 1, rows: 1]
  import Phoenix.HTML
  alias Asciinema.Media
  alias Asciinema.Recordings.Snapshot

  def svg_text_class(%{} = attrs) do
    classes =
      attrs
      |> Enum.reject(fn {attr, _} -> attr == "bg" end)
      |> Enum.map(&svg_text_class/1)
      |> Enum.filter(& &1)

    case classes do
      [] -> nil
      _ -> Enum.join(classes, " ")
    end
  end

  def svg_text_class({"fg", fg}) when is_integer(fg), do: "c-#{fg}"
  def svg_text_class({"bold", true}), do: "br"
  def svg_text_class({"faint", true}), do: "fa"
  def svg_text_class({"italic", true}), do: "it"
  def svg_text_class({"underline", true}), do: "un"
  def svg_text_class(_), do: nil

  def svg_rect_style(%{"bg" => [_r, _g, _b] = c}), do: "fill:#{hex(c)}"
  def svg_rect_style(%{"bg" => "rgb(" <> _ = c}), do: "fill:#{c}"
  def svg_rect_style(_), do: nil

  def svg_rect_class(%{"bg" => bg}) when is_integer(bg), do: "c-#{bg}"
  def svg_rect_class(_), do: nil

  def svg_text_style(%{"fg" => [_r, _g, _b] = c}), do: "fill:#{hex(c)}"
  def svg_text_style(%{"fg" => "rgb(" <> _ = c}), do: "fill:#{c}"
  def svg_text_style(_), do: nil

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
    lines = adjust_colors(asciicast.snapshot || [])
    bg_lines = add_coords(lines)

    text_lines =
      lines
      |> Snapshot.split_segments()
      |> add_coords()
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

  defp add_coords(lines) do
    for {segments, y} <- Enum.with_index(lines) do
      {_, segments} =
        Enum.reduce(segments, {0, []}, fn {text, attrs}, {x, segments} ->
          width = String.length(text)
          segment = %{text: text, attrs: attrs, x: x, width: width}
          {x + width, [segment | segments]}
        end)

      segments = Enum.reverse(segments)

      %{y: y, segments: segments}
    end
  end

  defp remove_blank_segments(lines) do
    for line <- lines do
      segments = Enum.reject(line.segments, &(String.trim(&1.text) == ""))
      %{line | segments: segments}
    end
  end
end
