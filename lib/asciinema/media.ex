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
      "original" when not is_nil(medium.term_theme_palette) ->
        Themes.custom_theme(medium.term_theme_fg, medium.term_theme_bg, medium.term_theme_palette)

      # "original" with nothing captured: fall back to the default named theme
      "original" ->
        Themes.named_theme(Accounts.default_term_theme_name(medium.user) || "asciinema")

      name ->
        Themes.named_theme(name)
    end
  end

  def original_theme(%{term_theme_name: "original"} = medium) do
    Themes.custom_theme(medium.term_theme_fg, medium.term_theme_bg, medium.term_theme_palette)
  end

  def original_theme(_medium), do: nil

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
