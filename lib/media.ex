defmodule Asciinema.Media do
  alias Asciinema.{Accounts, Themes}

  def theme_name(medium) do
    cond do
      medium.theme_name -> medium.theme_name
      medium.theme_palette -> nil
      true -> Accounts.default_theme_name(medium.user) || "asciinema"
    end
  end

  def theme(medium) do
    case theme_name(medium) do
      nil ->
        Themes.custom_theme(medium.theme_fg, medium.theme_bg, medium.theme_palette)

      name ->
        Themes.named_theme(name)
    end
  end

  def original_theme(medium) do
    case theme_name(medium) do
      nil ->
        Themes.custom_theme(medium.theme_fg, medium.theme_bg, medium.theme_palette)

      _name ->
        nil
    end
  end

  def font_family(medium) do
    case medium.terminal_font_family || Accounts.default_font_family(medium.user) do
      "default" -> nil
      family -> family
    end
  end
end
