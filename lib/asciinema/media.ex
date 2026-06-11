defmodule Asciinema.Media do
  alias Asciinema.{Accounts, Themes}

  def term_theme_name(medium) do
    medium.term_theme_name || Accounts.default_term_theme_name(medium.user)
  end

  @doc """
  True only with a captured palette — a medium can be set to "original" yet
  have none. Map.get: only streams have the prefer flag.
  """
  def uses_original_theme?(medium) do
    not is_nil(medium.term_theme_palette) and
      (medium.term_theme_name == "original" or
         Map.get(medium, :term_theme_prefer_original) == true)
  end

  @doc "The captured original theme, regardless of selection; nil when never captured."
  def original_theme(medium) do
    if medium.term_theme_palette do
      Themes.custom_theme(medium.term_theme_fg, medium.term_theme_bg, medium.term_theme_palette)
    end
  end

  def theme(medium) do
    if uses_original_theme?(medium) do
      original_theme(medium)
    else
      case term_theme_name(medium) do
        # "original" with nothing captured: fall back to the default named theme
        "original" -> Themes.named_theme(Accounts.default_term_theme_name(medium.user))
        name -> Themes.named_theme(name)
      end
    end
  end

  @doc """
  The auto/ prefix makes the player follow the theme embedded in the stream,
  falling back to the named one. Map.get: only streams have the prefer flag.
  """
  def player_theme_name(medium) do
    if Map.get(medium, :term_theme_prefer_original) do
      "auto/#{term_theme_name(medium)}"
    else
      term_theme_name(medium)
    end
  end

  def font_family(medium) do
    case medium.term_font_family || Accounts.default_font_family(medium.user) do
      "default" -> nil
      family -> family
    end
  end
end
