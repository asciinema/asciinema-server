defmodule AsciinemaWeb.UserController do
  use AsciinemaWeb, :controller
  alias Asciinema.Accounts
  alias Asciinema.Authorization, as: Authz
  alias Asciinema.Asciicasts
  alias AsciinemaWeb.Auth

  plug :clear_main_class
  plug :require_current_user when action in [:edit, :update]

  def new(conn, %{"t" => signup_token}) do
    conn
    |> put_session(:signup_token, signup_token)
    |> redirect(to: Routes.users_path(conn, :new))
  end

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, _params) do
    signup_token = get_session(conn, :signup_token)
    conn = delete_session(conn, :signup_token)

    case Accounts.verify_signup_token(signup_token) do
      {:ok, user} ->
        conn
        |> Auth.log_in(user)
        |> put_flash(:info, "Welcome to asciinema!")
        |> redirect(to: Routes.username_path(conn, :new))

      {:error, :token_invalid} ->
        conn
        |> put_flash(:error, "Invalid sign-up link.")
        |> redirect(to: Routes.login_path(conn, :new))

      {:error, :token_expired} ->
        conn
        |> put_flash(:error, "This sign-up link has expired, sorry.")
        |> redirect(to: Routes.login_path(conn, :new))

      {:error, :email_taken} ->
        conn
        |> put_flash(:error, "You already signed up with this email.")
        |> redirect(to: Routes.login_path(conn, :new))
    end
  end

  def show(conn, params) do
    with {:ok, user} <- fetch_user(params) do
      do_show(conn, params, user)
    end
  end

  defp do_show(conn, params, user) do
    current_user = conn.assigns.current_user
    user_is_self = !!(current_user && current_user.id == user.id)

    filter =
      case user_is_self do
        true -> :all
        false -> :public
      end

    page =
      Asciicasts.paginate_asciicasts(
        {user.id, filter},
        :date,
        params["page"],
        15
      )

    conn
    |> assign(:page_title, "#{user.username}'s profile")
    |> assign(:main_class, "")
    |> render(
      "show.html",
      user: user,
      user_is_self: user_is_self,
      asciicast_count: page.total_entries,
      page: page,
      show_edit_link: Authz.can?(current_user, :update, user)
    )
  end

  defp fetch_user(%{"id" => id}) do
    case Integer.parse(id) do
      {id, ""} -> Accounts.fetch_user(id)
      _ -> {:error, :not_found}
    end
  end

  defp fetch_user(%{"username" => username}) do
    Accounts.fetch_user(username: username)
  end

  def edit(conn, _params) do
    user = conn.assigns.current_user
    changeset = Accounts.change_user(user)
    render_edit_form(conn, user, changeset)
  end

  def update(conn, %{"user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Account settings saved.")
        |> redirect(to: profile_path(conn, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render_edit_form(conn, user, changeset)
    end
  end

  defp render_edit_form(conn, user, changeset) do
    api_tokens = Accounts.list_api_tokens(user)

    render(conn, "edit.html",
      changeset: changeset,
      api_tokens: api_tokens
    )
  end
end
