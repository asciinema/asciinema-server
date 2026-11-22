defmodule AsciinemaWeb.RecordingSVG do
  use Phoenix.Component
  alias Asciinema.Media
  alias Asciinema.Recordings.Snapshot
  alias AsciinemaWeb.TerminalSVG
  alias Phoenix.HTML

  embed_templates "recording_svg/*"

  def render_to_iodata(:thumbnail, asciicast) do
    %{asciicast: asciicast, standalone: true}
    |> thumbnail()
    |> HTML.Safe.to_iodata()
  end

  def render_to_iodata(:full, asciicast) do
    %{asciicast: asciicast}
    |> full()
    |> HTML.Safe.to_iodata()
  end

  # Bump when SVG rendering output can change without recording data changes.
  @svg_renderer_salt 18

  def svg_cache_key(asciicast) do
    theme = Media.theme(asciicast)

    key =
      if snapshot = asciicast.snapshot do
        Snapshot.to_ansi(snapshot)
      else
        to_string(asciicast.updated_at)
      end <>
        "\u0000" <>
        to_string(asciicast.term_bold_is_bright) <>
        "\u0000" <>
        to_string(asciicast.term_adaptive_palette) <>
        "\u0000" <>
        Integer.to_string(@svg_renderer_salt) <>
        "\u0000" <> :erlang.term_to_binary({theme.fg, theme.bg, theme.palette})

    :crypto.hash(:sha256, key)
    |> binary_part(0, 12)
    |> Base.url_encode64(padding: false)
  end

  attr :asciicast, :any, required: true
  attr :font_family, :string, default: nil
  attr :rx, :integer, default: nil
  attr :ry, :integer, default: nil

  def full(assigns) do
    ~H"""
    <TerminalSVG.preview
      snapshot={@asciicast.snapshot}
      theme={Media.theme(@asciicast)}
      cols={@asciicast.term_cols_override || @asciicast.term_cols}
      rows={@asciicast.term_rows_override || @asciicast.term_rows}
      bold_is_bright={@asciicast.term_bold_is_bright}
      adaptive_palette={@asciicast.term_adaptive_palette}
      font_family={@font_family}
      rx={@rx}
      ry={@ry}
      standalone={true}
    >
      <:overlay :let={viewport}>
        <.logo_overlay viewport={viewport} />
      </:overlay>
    </TerminalSVG.preview>
    """
  end

  attr :asciicast, :any, required: true
  attr :standalone, :boolean, default: false

  def thumbnail(assigns) do
    ~H"""
    <TerminalSVG.thumbnail
      snapshot={@asciicast.snapshot}
      theme={Media.theme(@asciicast)}
      bold_is_bright={@asciicast.term_bold_is_bright}
      adaptive_palette={@asciicast.term_adaptive_palette}
      standalone={@standalone}
    />
    """
  end

  attr :viewport, :map, required: true

  defp logo_overlay(assigns) do
    %{width: width, height: height} = assigns.viewport
    size = Float.round(min(width, height) * 0.2, 3)

    assigns =
      assign(assigns,
        size: size,
        x: Float.round((width - size) / 2, 3),
        y: Float.round((height - size) / 2, 3)
      )

    ~H"""
    <svg x={@x} y={@y} width={@size} height={@size}>
      <.logo />
    </svg>
    """
  end
end
