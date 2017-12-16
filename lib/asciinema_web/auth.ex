defmodule AsciinemaWeb.Auth do
  import Plug.Conn
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]
  import AsciinemaWeb.Plug.ReturnTo
  alias Plug.Conn
  alias Asciinema.Accounts.User
  alias Asciinema.Repo

  @user_key "warden.user.user.key"
  @one_year_in_secs 31_557_600

  def init(opts) do
    opts
  end

  def call(%Conn{assigns: %{current_user: %User{}}} = conn, _opts) do
    conn
  end
  def call(conn, _opts) do
    user_id = get_session(conn, @user_key)
    user = user_id && Repo.get(User, user_id)

    if user do
      Sentry.Context.set_user_context(%{id: user.id,
                                        username: user.username,
                                        email: user.email})
    end

    assign(conn, :current_user, user)
  end

  def require_current_user(%Conn{assigns: %{current_user: %User{}}} = conn, _) do
    conn
  end
  def require_current_user(conn, opts) do
    msg = Keyword.get(opts, :flash, "Please log in first.")

    conn
    |> save_return_path
    |> put_flash(:info, msg)
    |> redirect(to: "/login/new")
    |> halt
  end

  def log_in(conn, %User{} = user) do
    user = user |> User.login_changeset |> Repo.update!

    conn
    |> put_session(@user_key, user.id)
    |> put_resp_cookie("auth_token", user.auth_token, max_age: @one_year_in_secs)
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
