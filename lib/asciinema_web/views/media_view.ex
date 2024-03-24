defmodule AsciinemaWeb.MediaView do
  use AsciinemaWeb, :view
  alias Asciinema.{Fonts, Themes}
  alias AsciinemaWeb.UserHTML

  @container_vertical_padding 2 * 4
  @approx_char_width 7
  @approx_char_height 16

  def cinema_height(cols, rows) do
    ratio = rows * @approx_char_height / (cols * @approx_char_width)
    round(@container_vertical_padding + 100 * ratio)
  end

  def author_username(%{user: user}) do
    UserHTML.username(user)
  end

  def author_avatar_url(%{user: user}) do
    UserHTML.avatar_url(user)
  end

  def author_profile_path(%{user: user}) do
    profile_path(user)
  end

  def author_profile_url(%{user: user}) do
    profile_url(user)
  end

  def theme_options do
    for theme <- Themes.terminal_themes() do
      {Themes.display_name(theme), theme}
    end
  end

  def font_family_options do
    for family <- Fonts.terminal_font_families() do
      {Fonts.display_name(family), family}
    end
  end
end
