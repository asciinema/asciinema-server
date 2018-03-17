defmodule AsciinemaWeb.UserView do
  use AsciinemaWeb, :view
  alias Asciinema.Gravatar

  def avatar_url(user) do
    username = username(user)
    email = user.email || "#{username}+#{user.id}@asciinema.org"
    Gravatar.gravatar_url(email)
  end

  def username(user) do
    user.username || user.temporary_username || "user:#{user.id}"
  end

  def theme_name(user) do
    user.theme_name
  end

  def theme_options do
    [
      {"asciinema", "asciinema"},
      {"Tango", "tango"},
      {"Solarized Dark", "solarized-dark"},
      {"Solarized Light", "solarized-light"},
      {"Monokai", "monokai"},
    ]
  end

  def active_tokens(api_tokens) do
    api_tokens
    |> Enum.reject(&(&1.revoked_at))
    |> Enum.sort_by(&(- Timex.to_unix(&1.created_at)))
  end

  def revoked_tokens(api_tokens) do
    api_tokens
    |> Enum.filter(&(&1.revoked_at))
    |> Enum.sort_by(&(- Timex.to_unix(&1.created_at)))
  end
end
