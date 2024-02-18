defmodule AsciinemaWeb.PlayerView do
  use AsciinemaWeb, :view
  alias Asciinema.Media
  alias AsciinemaWeb.UserView

  @container_vertical_padding 2 * 4
  @approx_char_width 7
  @approx_char_height 16

  def cinema_height(cols, rows) do
    ratio = rows * @approx_char_height / (cols * @approx_char_width)
    round(@container_vertical_padding + 100 * ratio)
  end

  def author_username(%{user: user}) do
    UserView.username(user)
  end

  def author_avatar_url(%{user: user}) do
    UserView.avatar_url(user)
  end

  def author_profile_path(%{user: user}) do
    profile_path(user)
  end

  def author_profile_url(%{user: user}) do
    profile_url(user)
  end

  def theme_options do
    for theme <- Media.themes() do
      {theme_display_name(theme), theme}
    end
  end

  def theme_name(medium) do
    medium.theme_name || default_theme_name(medium)
  end

  def theme_display_name(theme) do
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

  def default_theme_name(%{user: user}) do
    UserView.theme_name(user) || "asciinema"
  end

  def terminal_font_family_options do
    for family <- Media.terminal_font_families() do
      {terminal_font_family_display_name(family), family}
    end
  end

  def terminal_font_family(medium) do
    case medium.terminal_font_family || default_terminal_font_family(medium) do
      "default" -> nil
      family -> family
    end
  end

  def terminal_font_family_display_name(family) do
    case family do
      "default" -> "System monospace, web safe"
      "FiraCode Nerd Font" -> "Nerd Font - Fira Code"
      "JetBrainsMono Nerd Font" -> "Nerd Font - JetBrains Mono"
    end
  end

  def default_terminal_font_family(%{user: user}) do
    UserView.terminal_font_family(user)
  end
end
