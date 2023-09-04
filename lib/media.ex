defmodule Asciinema.Media do
  @custom_terminal_font_families [
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

  def custom_terminal_font_families, do: @custom_terminal_font_families

  def themes, do: @themes
end
