defmodule AsciinemaWeb.UserView do
  use AsciinemaWeb, :view
  import Scrivener.HTML
  alias AsciinemaWeb.PlayerView
  alias Asciinema.Gravatar

  defdelegate theme_options, to: PlayerView
  defdelegate terminal_font_family_options, to: PlayerView
  defdelegate terminal_font_family_display_name(asciicast), to: PlayerView

  def avatar_url(user) do
    username = username(user)
    email = user.email || "#{username}+#{user.id}@asciinema.org"
    Gravatar.gravatar_url(email)
  end

  def username(user) do
    user.username || user.temporary_username || "user:#{user.id}"
  end

  def display_name(user) do
    if String.trim("#{user.name}") != "" do
      user.name
    end
  end

  def joined_at(user) do
    Timex.format!(user.inserted_at, "{Mfull} {D}, {YYYY}")
  end

  def theme_name(user) do
    user.theme_name
  end

  def terminal_font_family(user) do
    user.terminal_font_family
  end

  def default_font_display_name do
    terminal_font_family_display_name("default")
  end

  def active_tokens(api_tokens) do
    api_tokens
    |> Enum.reject(& &1.revoked_at)
    |> Enum.sort_by(&(-Timex.to_unix(&1.inserted_at)))
  end

  def revoked_tokens(api_tokens) do
    api_tokens
    |> Enum.filter(& &1.revoked_at)
    |> Enum.sort_by(&(-Timex.to_unix(&1.inserted_at)))
  end
end
