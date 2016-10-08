defmodule Asciinema.Auth do
  alias Asciinema.{Repo, User}
  alias Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    user_id = Conn.get_session(conn, "warden.user.user.key")
    user = user_id && Repo.get(User, user_id)
    Conn.assign(conn, :current_user, user)
  end
end
