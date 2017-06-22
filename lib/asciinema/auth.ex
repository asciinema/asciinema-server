defmodule Asciinema.Auth do
  import Plug.Conn
  alias Asciinema.{Repo, User}

  @user_key "warden.user.user.key"

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    user_id = get_session(conn, @user_key)
    user = user_id && Repo.get(User, user_id)
    assign(conn, :current_user, user)
  end

  def login(conn, %User{id: id} = user) do
    conn
    |> put_session(@user_key, id)
    |> assign(:current_user, user)
  end

  def get_basic_auth(conn) do
    with ["Basic " <> auth] <- get_req_header(conn, "authorization"),
         auth = String.replace(auth, ~r/^%/, ""), # workaround for 1.3.0-1.4.0 client bug
         {:ok, username_password} <- Base.decode64(auth),
         [username, password] <- String.split(username_password, ":") do
      {username, password}
    else
      _ -> nil
    end
  end

  def put_basic_auth(conn, nil, nil) do
    conn
  end
  def put_basic_auth(conn, username, password) do
    auth = Base.encode64("#{username}:#{password}")
    put_req_header(conn, "authorization", "Basic " <> auth)
  end
end
