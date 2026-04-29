defmodule AsciinemaWeb.LoginController do
  use AsciinemaWeb, :controller
  require Logger

  plug :detect_bot when action == :create

  def new(conn, _params) do
    render(conn, :new)
  end

  def create(%{assigns: %{bot_triggers: triggers}} = conn, _params) do
    Logger.warning("bot login attempt detected: honeypot_fields=#{Enum.join(triggers, ",")}")

    redirect(conn, to: ~p"/login/sent")
  end

  def create(conn, %{"login" => %{"email" => identifier}}) do
    result = Asciinema.initiate_login(String.trim(identifier), AsciinemaWeb.UrlProvider)

    case result do
      :ok ->
        redirect(conn, to: ~p"/login/sent")

      {:error, :user_not_found} ->
        render(conn, :new, error: "No user found for given username.")

      {:error, :email_invalid} ->
        render(conn, :new, error: "This doesn't look like a correct email address.")

      {:error, :email_missing} ->
        redirect(conn, to: ~p"/login/sent")

      {:error, reason} ->
        Logger.warning("email delivery error: #{inspect(reason)}")

        render(conn, :new, error: "Error sending email, please try again later.")
    end
  end

  def sent(conn, _params) do
    render(conn, :sent)
  end

  defp detect_bot(conn, _opts) do
    case honeypot_triggers(conn.params["login"]) do
      [] ->
        conn

      triggers ->
        conn
        |> assign(:bot_triggers, triggers)
        |> put_resp_header("x-melliculum", "machina")
    end
  end

  defp honeypot_triggers(%{"username" => "", "terms" => _}), do: [:terms]
  defp honeypot_triggers(%{"username" => ""}), do: []
  defp honeypot_triggers(%{"terms" => _}), do: [:username, :terms]
  defp honeypot_triggers(_), do: [:username]
end
