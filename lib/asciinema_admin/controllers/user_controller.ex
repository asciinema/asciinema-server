defmodule AsciinemaAdmin.UserController do
  use AsciinemaAdmin, :controller
  alias Ecto.Changeset
  alias Asciinema.Accounts

  def index(conn, _params) do
    users = Accounts.list_users()

    render(conn, :index, users: users)
  end

  def new(conn, _params) do
    render(conn, :new, changeset: Accounts.new_user())
  end

  def create(conn, %{"user" => attrs}) do
    case Accounts.create_user(attrs) do
      {:ok, user} ->
        redirect(conn, to: ~p"/admin/users/#{user}")

      {:error, changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id} = params) do
    user = Accounts.get_user(id)
    clis = Accounts.list_clis(user)

    changeset =
      user
      |> Accounts.new_cli()
      |> put_error(params["error"])

    render(conn, :show, user: user, clis: clis, changeset: changeset)
  end

  defp put_error(changeset, nil), do: changeset

  defp put_error(changeset, error) do
    {:error, changeset} =
      changeset
      |> Changeset.add_error(:token, humanize_error(error))
      |> Changeset.apply_action(:insert)

    changeset
  end

  defp humanize_error(reason) do
    case reason do
      "token_invalid" -> "invalid install ID - must be a UUID"
      "token_taken" -> "this CLI is already assigned to another user"
      "cli_revoked" -> "this CLI has already been revoked"
      reason -> "error authorizing CLI: #{reason}"
    end
  end

  def lookup(conn, %{"q" => %{"id" => id}}) do
    case Integer.parse(id) do
      {id, ""} ->
        redirect(conn, to: ~p"/admin/users/#{id}")

      _otherwise ->
        redirect(conn, to: ~p"/admin/users")
    end
  end

  def lookup(conn, %{"q" => %{"username" => username}}) do
    if user = Accounts.find_user(username) do
      redirect(conn, to: ~p"/admin/users/#{user.id}")
    else
      redirect(conn, to: ~p"/admin/users")
    end
  end

  def lookup(conn, %{"q" => %{"email" => email}}) do
    if user = Accounts.find_user(email) do
      redirect(conn, to: ~p"/admin/users/#{user.id}")
    else
      redirect(conn, to: ~p"/admin/users")
    end
  end

  def edit(conn, %{"id" => id}) do
    user = Accounts.get_user(id)
    changeset = Accounts.change_user(user)

    render(conn, :edit, user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => attrs}) do
    user = Accounts.get_user(id)

    case Asciinema.update_user(user, attrs) do
      {:ok, user} ->
        redirect(conn, to: ~p"/admin/users/#{user.id}")

      {:error, changeset} ->
        render(conn, :edit, user: user, changeset: changeset)
    end
  end
end
