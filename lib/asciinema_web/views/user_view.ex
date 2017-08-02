defmodule AsciinemaWeb.UserView do
  use AsciinemaWeb, :view
  alias Asciinema.Accounts.User
  alias Asciinema.Gravatar

  def avatar_url(user) do
    username = user_username(user)
    email = user.email || "#{username}+#{user.id}@asciinema.org"
    Gravatar.gravatar_url(email)
  end

  def profile_path(%User{id: id, username: username}) do
    if username do
      "/~#{username}"
    else
      "/u/#{id}"
    end
  end

  defp user_username(user) do
    user.username || user.temporary_username || "user:#{user.id}"
  end
end
