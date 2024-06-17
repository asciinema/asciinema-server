defmodule AsciinemaWeb.Plug.Authn do
  import Plug.Conn
  alias AsciinemaWeb.Authentication
  alias Plug.Conn

  def init(opts), do: opts

  def call(%Conn{assigns: %{current_user: user}} = conn, _opts) when not is_nil(user), do: conn

  def call(conn, _opts) do
    conn
    |> assign(:current_user, nil)
    |> assign(:default_stream, nil)
    |> Authentication.try_log_in_from_session()
    |> Authentication.try_log_in_from_cookie()
    |> setup_sentry_context()
  end

  defp setup_sentry_context(%Conn{assigns: %{current_user: nil}} = conn), do: conn

  defp setup_sentry_context(%Conn{assigns: %{current_user: user}} = conn) do
    Sentry.Context.set_user_context(%{
      id: user.id,
      username: user.username,
      email: user.email
    })

    conn
  end
end
