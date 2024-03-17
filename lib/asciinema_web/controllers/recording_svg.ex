defmodule AsciinemaWeb.RecordingSVG do
  use Phoenix.Component
  import AsciinemaWeb.RecordingHTML, only: [cols: 1, rows: 1]
  import Phoenix.HTML
  alias Asciinema.{Media, Themes}
  alias Asciinema.Recordings.Snapshot

  embed_templates "recording/*.svg"
  embed_templates "recording/themes/*.svg", suffix: "_theme"

  defdelegate text_coords(snapshot), to: Snapshot
  defdelegate bg_coords(snapshot), to: Snapshot

  def text_extra_attrs(attrs, theme),
    do: %{style: text_style(attrs, theme), class: text_class(attrs)}

  defp text_style(%{"fg" => fg}, theme) when is_integer(fg),
    do: "fill: #{Themes.color(theme, fg)}"

  defp text_style(%{"fg" => [_r, _g, _b] = c}, _theme), do: "fill: #{hex(c)}"
  defp text_style(%{"fg" => "rgb(" <> _ = c}, _theme), do: "fill: #{c}"
  defp text_style(_, _), do: nil

  defp text_class(%{} = attrs) do
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

  defp text_class({"bold", true}), do: "br"
  defp text_class({"faint", true}), do: "fa"
  defp text_class({"italic", true}), do: "it"
  defp text_class({"underline", true}), do: "un"
  defp text_class(_), do: nil

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
      rx={0}
      ry={0}
      logo={false}
    />
    """
  end

  defp snapshot(asciicast, nil) do
    Snapshot.new(asciicast.snapshot || [])
  end

  defp snapshot(asciicast, {cols, rows}) do
    (asciicast.snapshot || [])
    |> Snapshot.new()
    |> Snapshot.crop(cols, rows)
  end
end
