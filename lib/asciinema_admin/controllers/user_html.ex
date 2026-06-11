defmodule AsciinemaAdmin.UserHTML do
  use AsciinemaAdmin, :html

  alias Asciinema.Themes

  embed_templates "user_html/*"

  # users only have named-theme preferences (no captured original palette)
  def theme_colors(user) do
    named_theme_colors(user.term_theme_name || Themes.default_name())
  end

  def theme_name(user) do
    if user.term_theme_name do
      Themes.display_name(user.term_theme_name)
    else
      Themes.display_name(Themes.default_name()) <> " (default)"
    end
  end
end
