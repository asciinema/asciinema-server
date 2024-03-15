defmodule AsciinemaWeb.RecordingSVG do
  use Phoenix.Component
  import AsciinemaWeb.RecordingHTML, only: [cols: 1, rows: 1]
  import Phoenix.HTML
  alias Asciinema.{Media, Themes}
  alias Asciinema.Recordings.Snapshot

  embed_templates "recording/*.svg"
  embed_templates "recording/themes/*.svg", suffix: "_theme"

  def text_style(%{"fg" => fg}, theme) when is_integer(fg), do: "fill: #{Themes.color(theme, fg)}"
  def text_style(%{"fg" => [_r, _g, _b] = c}, _theme), do: "fill: #{hex(c)}"
  def text_style(%{"fg" => "rgb(" <> _ = c}, _theme), do: "fill: #{c}"
  def text_style(_, _), do: nil

  def text_class(%{} = attrs) do
    classes =
      attrs
      |> Enum.map(&text_class/1)
      |> Enum.filter(& &1)
      |> Enum.uniq()

    case classes do
      [] -> nil
      _ -> Enum.join(classes, " ")
    end
  end

  def text_class({"bold", true}), do: "br"
  def text_class({"faint", true}), do: "fa"
  def text_class({"italic", true}), do: "it"
  def text_class({"underline", true}), do: "un"
  def text_class(_), do: nil

  def bg_style(%{"bg" => bg}, theme) when is_integer(bg), do: "fill: #{Themes.color(theme, bg)}"
  def bg_style(%{"bg" => [_r, _g, _b] = c}, _theme), do: "fill: #{hex(c)}"
  def bg_style(%{"bg" => "rgb(" <> _ = c}, _theme), do: "fill: #{c}"
  def bg_style(_), do: nil

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

  def show(assigns) do
    ~H"""
    <%= raw("<?xml version=\"1.0\"?>") %>
    <.preview
      snapshot={snapshot(@asciicast, nil)}
      cols={cols(@asciicast)}
      rows={rows(@asciicast)}
      theme={Media.theme(@asciicast)}
      font_family={assigns[:font_family]}
      rx={assigns[:rx]}
      ry={assigns[:ry]}
      logo={true}
    />
    """
  end

  def thumbnail(assigns) do
    ~H"""
    <.preview
      snapshot={snapshot(@asciicast, {80, 15})}
      cols={80}
      rows={15}
      theme={Media.theme(@asciicast)}
      font_family={assigns[:font_family]}
      logo={false}
    />
    """
  end

  defp snapshot(asciicast, nil) do
    Snapshot.new(asciicast.snapshot)
  end

  defp snapshot(asciicast, {cols, rows}) do
    asciicast.snapshot
    |> Snapshot.new()
    |> Snapshot.window(cols, rows)
    |> Snapshot.new()
  end

  defp text(snapshot) do
    snapshot
    |> Snapshot.regroup(:cells)
    |> Snapshot.coords()
    |> remove_blank_text()
  end

  defp background(snapshot) do
    snapshot
    |> Snapshot.regroup(:segments)
    |> Snapshot.coords()
    |> remove_default_background()
  end

  defp remove_blank_text(lines) do
    for line <- lines do
      %{line | segments: Enum.reject(line.segments, &(String.trim(&1.text) == ""))}
    end
  end

  defp remove_default_background(lines) when is_list(lines) do
    lines
    |> Enum.map(&remove_default_background/1)
    |> Enum.filter(&(length(&1.segments) > 0))
  end

  defp remove_default_background(%{segments: segments} = line) do
    %{line | segments: Enum.filter(segments, & &1.attrs["bg"])}
  end
end
