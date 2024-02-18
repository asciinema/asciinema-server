defmodule Asciinema.Media do
  @terminal_font_families [
    "default",
    "FiraCode Nerd Font",
    "JetBrainsMono Nerd Font"
  ]

  @themes [
    "asciinema",
    "dracula",
    "monokai",
    "nord",
    "solarized-dark",
    "solarized-light",
    "tango"
  ]

  def terminal_font_families, do: @terminal_font_families

  def themes, do: @themes
end
