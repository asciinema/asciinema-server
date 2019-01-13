defmodule AsciinemaWeb.UserController do
  use AsciinemaWeb, :controller
  alias Asciinema.Accounts
  alias Asciinema.Authorization, as: Authz
  alias Asciinema.Asciicasts
  alias AsciinemaWeb.Auth

  plug :require_current_user when action in [:edit, :update]

  def new(conn, %{"t" => signup_token}) do
    conn
    |> put_session(:signup_token, signup_token)
    |> redirect(to: users_path(conn, :new))
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
        |> redirect(to: "/username/new")

      {:error, :token_invalid} ->
        conn
        |> put_flash(:error, "Invalid sign-up link.")
        |> redirect(to: login_path(conn, :new))

      {:error, :token_expired} ->
        conn
        |> put_flash(:error, "This sign-up link has expired, sorry.")
        |> redirect(to: login_path(conn, :new))

      {:error, :email_taken} ->
        conn
        |> put_flash(:error, "You already signed up with this email.")
        |> redirect(to: login_path(conn, :new))
    end
  end

  def show(conn, params) do
    current_user = conn.assigns.current_user

    user =
      case params do
        %{"username" => username} ->
          Accounts.find_user_by_username!(username)

        %{"id" => id} ->
          Accounts.get_user!(id)
      end

    user_is_self = !!(current_user && (current_user.id == user.id))

    asciicasts =
      case user_is_self do
        true -> Accounts.asciicasts(user, :all)
        false -> Accounts.asciicasts(user, :public)
      end

    asciicast_count = Asciicasts.count_asciicasts(asciicasts)
    page = Asciicasts.paginate_asciicasts(asciicasts, :date, params["page"], 15)

    conn
    |> put_layout(:app2)
    |> assign(:page_title, "#{user.username}'s profile")
    |> assign(:main_class, "")
    |> render(
      "show.html",
      user: user,
      user_is_self: user_is_self,
      asciicast_count: asciicast_count,
      page: page,
      show_edit_link: Authz.can?(current_user, :update, user)
    )
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
      api_tokens: api_tokens)
  end
end
