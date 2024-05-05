defmodule AsciinemaWeb.UsernameController do
  use AsciinemaWeb, :new_controller
  alias Asciinema.Accounts

  plug :require_current_user

  def new(conn, _params) do
    user = conn.assigns.current_user
    changeset = Accounts.change_user(user)
    render(conn, "new.html", user: user, changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        redirect(conn, to: profile_path(conn, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        error =
          case Keyword.get(changeset.errors, :username) do
            {_msg, [{_, :format}]} -> :username_invalid
            {_msg, [{_, :required}]} -> :username_invalid
            {_msg, _} -> :username_taken
          end

        conn
        |> put_status(422)
        |> render(
          "new.html",
          user: user,
          error: error,
          changeset: changeset
        )
    end
  end

  def skip(conn, _params) do
    redirect(conn, to: profile_path(conn, conn.assigns.current_user))
  end
end
