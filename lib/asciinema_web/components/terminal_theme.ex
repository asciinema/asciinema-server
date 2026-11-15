defmodule AsciinemaWeb.TerminalTheme do
  use Phoenix.Component

  attr :theme, :any, required: true
  attr :selector, :string, default: "section.cinema, div.ap-player"

  def style(assigns) do
    ~H"""
    <style>
      <%= @selector %> {
        <%= variables(@theme) %>
      }
    </style>
    """
  end

  # Literal hex values are required by the player's CSS palette reader.
  defp variables(theme) do
    colors = [{"foreground", theme.fg}, {"background", theme.bg}]

    colors =
      colors ++ Enum.map(Enum.with_index(Tuple.to_list(theme.palette)), fn {c, i} -> {i, c} end)

    Enum.map_join(colors, "\n", fn {name, color} -> "--term-color-#{name}: #{color};" end)
  end
end
