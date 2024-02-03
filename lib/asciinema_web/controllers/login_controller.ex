defmodule AsciinemaWeb.LoginController do
  use AsciinemaWeb, :new_controller
  require Logger

  plug :clear_main_class
  plug :detect_bot when action == :create

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(%{assigns: %{bot: true}} = conn, params) do
    Logger.warn("bot login attempt: #{inspect(params)}")

    redirect(conn, to: ~p"/login/sent")
  end

  def create(conn, %{"login" => %{"email" => identifier}}) do
    identifier = String.trim(identifier)

    result =
      Asciinema.send_login_email(
        identifier,
        Map.get(conn.assigns, :cfg_sign_up_enabled?, true),
        AsciinemaWeb
      )

    case result do
      :ok ->
        redirect(conn, to: ~p"/login/sent")

      {:error, :user_not_found} ->
        render(conn, :new, error: "No user found for given username.")

      {:error, :email_invalid} ->
        render(conn, :new, error: "This doesn't look like a correct email address.")

      {:error, :email_missing} ->
        redirect(conn, to: ~p"/login/sent")
    end
  end

  def sent(conn, _params) do
    render(conn, :sent)
  end

  defp detect_bot(conn, _opts) do
    login = conn.params["login"]

    if username_touched?(login) || terms_touched?(login) do
      conn
      |> assign(:bot, true)
      |> put_resp_header("x-melliculum", "machina")
    else
      conn
    end
  end

  defp username_touched?(%{"username" => ""}), do: false
  defp username_touched?(_), do: true

  defp terms_touched?(%{"terms" => _}), do: true
  defp terms_touched?(_), do: false
end
