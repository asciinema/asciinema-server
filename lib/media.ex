defmodule Asciinema.Media do
  alias Asciinema.Accounts

  def theme_name(medium) do
    medium.theme_name || Accounts.default_theme_name(medium.user) || "asciinema"
  end

  def font_family(medium) do
    case medium.terminal_font_family || Accounts.default_font_family(medium.user) do
      "default" -> nil
      family -> family
    end
  end
end
