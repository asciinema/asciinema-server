defmodule AsciinemaWeb.Authentication do
  import Plug.Conn
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]
  import AsciinemaWeb.Plug.ReturnTo
  alias Plug.Conn
  alias Asciinema.{Accounts, Streaming}
  alias Asciinema.Accounts.User
  alias AsciinemaWeb.Endpoint
  alias AsciinemaWeb.Router.Helpers, as: Routes

  @user_key "user_id"
  @token_cookie_name "auth_token"
  @token_max_age 90 * 24 * 60 * 60

  def try_log_in_from_session(conn) do
    user_id = get_session(conn, @user_key)

    with user_id when not is_nil(user_id) <- user_id,
         user when not is_nil(user) <- Accounts.get_user(user_id) do
      conn
      |> assign(:current_user, user)
      |> assign(:default_stream, user_stream(user))
    else
      _ -> conn
    end
  end

  def try_log_in_from_cookie(%Conn{assigns: %{current_user: nil}} = conn) do
    with auth_token when not is_nil(auth_token) <- conn.req_cookies[@token_cookie_name],
         user when not is_nil(user) <- Accounts.find_user_by_auth_token(auth_token) do
      refresh_session(conn, user)
    else
      _ -> conn
    end
  end

  def try_log_in_from_cookie(conn), do: conn

  def require_current_user(%Conn{assigns: %{current_user: %User{}}} = conn, _) do
    conn
  end

  def require_current_user(conn, opts) do
    msg = Keyword.get(opts, :flash, "Please log in first.")

    conn
    |> save_return_path()
    |> put_flash(:info, msg)
    |> redirect(to: Routes.login_path(conn, :new))
    |> halt()
  end

  def require_admin(%Conn{assigns: %{current_user: %User{is_admin: true}}} = conn, _) do
    conn
  end

  def require_admin(conn, _) do
    conn
    |> put_flash(:error, "Access denied.")
    |> redirect(to: Endpoint.path("/"))
    |> halt()
  end

  def log_in(conn, %User{} = user) do
    Accounts.update_last_login(user)

    refresh_session(conn, user)
  end

  def refresh_session(conn, user) do
    user = Accounts.regenerate_auth_token(user)

    conn
    |> put_session(@user_key, user.id)
    |> put_resp_cookie(@token_cookie_name, user.auth_token, max_age: @token_max_age)
    |> assign(:current_user, user)
    |> assign(:default_stream, user_stream(user))
  end

  def log_out(conn) do
    conn
    |> delete_session(@user_key)
    |> delete_resp_cookie(@token_cookie_name)
    |> assign(:current_user, nil)
  end

  def get_basic_auth(conn) do
    with ["Basic " <> auth] <- get_req_header(conn, "authorization"),
         # workaround for 1.3.0-1.4.0 client bug
         auth = String.replace(auth, ~r/^%/, ""),
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

  defp user_stream(user), do: Streaming.get_live_stream(user, nil)
end
