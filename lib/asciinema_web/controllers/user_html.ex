defmodule AsciinemaWeb.UserHTML do
  use AsciinemaWeb, :html
  import AsciinemaWeb.ErrorHelpers
  import Scrivener.HTML
  alias Asciinema.{Fonts, Gravatar}
  alias AsciinemaWeb.{MediaView, RecordingHTML}

  embed_templates "user/*"

  defdelegate theme_options, to: MediaView
  defdelegate font_family_options, to: MediaView
  defdelegate default_font_display_name, to: Fonts

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
