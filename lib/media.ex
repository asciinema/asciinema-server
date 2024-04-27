defmodule Asciinema.Media do
  alias Asciinema.{Accounts, Themes}

  def theme_name(medium) do
    cond do
      medium.theme_name -> medium.theme_name
      true -> Accounts.default_theme_name(medium.user) || "asciinema"
    end
  end

  def theme(%{theme_prefer_original: true, theme_palette: p} = medium) when not is_nil(p) do
    Themes.custom_theme(medium.theme_fg, medium.theme_bg, p)
  end

  def theme(medium) do
    case theme_name(medium) do
      "original" ->
        Themes.custom_theme(medium.theme_fg, medium.theme_bg, medium.theme_palette)

      name ->
        Themes.named_theme(name)
    end
  end

  def original_theme(%{theme_name: "original"} = medium) do
    Themes.custom_theme(medium.theme_fg, medium.theme_bg, medium.theme_palette)
  end

  def original_theme(_medium), do: nil

  def font_family(medium) do
    case medium.terminal_font_family || Accounts.default_font_family(medium.user) do
      "default" -> nil
      family -> family
    end
  end
end
