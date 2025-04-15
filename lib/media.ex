defmodule Asciinema.Media do
  alias Asciinema.{Accounts, Themes}

  def term_theme_name(medium) do
    cond do
      medium.term_theme_name -> medium.term_theme_name
      true -> Accounts.default_term_theme_name(medium.user) || "asciinema"
    end
  end

  def theme(%{term_theme_prefer_original: true, term_theme_palette: p} = medium)
      when not is_nil(p) do
    Themes.custom_theme(medium.term_theme_fg, medium.term_theme_bg, p)
  end

  def theme(medium) do
    case term_theme_name(medium) do
      "original" ->
        Themes.custom_theme(medium.term_theme_fg, medium.term_theme_bg, medium.term_theme_palette)

      name ->
        Themes.named_theme(name)
    end
  end

  def original_theme(%{term_theme_name: "original"} = medium) do
    Themes.custom_theme(medium.term_theme_fg, medium.term_theme_bg, medium.term_theme_palette)
  end

  def original_theme(_medium), do: nil

  def font_family(medium) do
    case medium.term_font_family || Accounts.default_font_family(medium.user) do
      "default" -> nil
      family -> family
    end
  end
end
