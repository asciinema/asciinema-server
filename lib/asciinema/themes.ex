defmodule Asciinema.Themes do
  @terminal_themes [
    "asciinema",
    "dracula",
    "monokai",
    "nord",
    "solarized-dark",
    "solarized-light",
    "tango"
  ]

  def terminal_themes, do: @terminal_themes

  def display_name(theme) do
    case theme do
      "asciinema" -> "asciinema"
      "dracula" -> "Dracula"
      "monokai" -> "Monokai"
      "nord" -> "Nord"
      "tango" -> "Tango"
      "solarized-dark" -> "Solarized Dark"
      "solarized-light" -> "Solarized Light"
    end
  end
end
