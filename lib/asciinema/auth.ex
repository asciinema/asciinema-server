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

  def get_basic_auth(conn) do
    with ["Basic " <> auth] <- Conn.get_req_header(conn, "authorization"),
         {:ok, username_password} <- Base.decode64(auth),
         [username, password] <- String.split(username_password, ":") do
      {username, password}
    else
      _ -> nil
    end
  end
end
