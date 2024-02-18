defmodule Asciinema.Fonts do
  @terminal_font_families [
    "default",
    "FiraCode Nerd Font",
    "JetBrainsMono Nerd Font"
  ]

  def terminal_font_families, do: @terminal_font_families

  def display_name(family) do
    case family do
      "default" -> "System monospace, web safe"
      "FiraCode Nerd Font" -> "Nerd Font - Fira Code"
      "JetBrainsMono Nerd Font" -> "Nerd Font - JetBrains Mono"
    end
  end

  def default_font_display_name, do: display_name("default")
end
