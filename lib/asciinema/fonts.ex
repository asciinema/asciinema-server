defmodule Asciinema.Fonts do
  @terminal_font_families [
    "default",
    "Fira Code",
    "JetBrains Mono"
  ]

  def terminal_font_families, do: @terminal_font_families

  def display_name(family) do
    case family do
      "default" -> "System monospace, web safe"
      _ -> family
    end
  end

  def default_font_display_name, do: display_name("default")
end
