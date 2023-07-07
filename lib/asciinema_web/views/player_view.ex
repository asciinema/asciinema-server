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

  def theme_name(medium) do
    medium.theme_name || default_theme_name(medium)
  end

  def default_theme_name(%{user: user}) do
    UserView.theme_name(user) || "asciinema"
  end

  def terminal_font_family_options do
    for family <- Media.custom_terminal_font_families() do
      case family do
        "FiraCode Nerd Font" -> {"Nerd Font - Fira Code", family}
        "JetBrainsMono Nerd Font" -> {"Nerd Font - JetBrains Mono", family}
      end
    end
  end
end
