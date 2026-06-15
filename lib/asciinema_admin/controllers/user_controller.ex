defmodule AsciinemaAdmin.UserController do
  use AsciinemaAdmin, :controller

  alias Asciinema.{Accounts, Recordings, Streaming}
  alias Asciinema.Recordings.Query, as: RecordingQuery
  alias Asciinema.Streaming.Query, as: StreamQuery
  alias AsciinemaAdmin.IndexQuery

  @page_size 50

  def index(conn, params) do
    index = IndexQuery.build(:users, params)

    page =
      if index.valid? do
        Accounts.paginate(index.query, params["page"], @page_size, with_counts: true)
      else
        IndexQuery.empty_page(params["page"], @page_size)
      end

    render(conn, :index,
      page_title: "Users",
      users: page.entries,
      page: page,
      index: index,
      filter_params: index.query_params
    )
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    clis = Accounts.list_clis(user)
    login_url = AsciinemaWeb.UrlProvider.login(Accounts.generate_login_token(user))
    {compressed, uncompressed} = Recordings.byte_totals(user.id)

    render(conn, :show,
      page_title: user.username || user.email || "User ##{user.id}",
      user: user,
      clis: clis,
      cli_changeset: Accounts.new_cli(user),
      recording_count: user_recording_count(user.id),
      stream_count: user_stream_count(user.id),
      bytes_compressed: compressed,
      bytes_uncompressed: uncompressed,
      login_url: login_url
    )
  end

  def new(conn, _params) do
    render(conn, :new,
      page_title: "New user",
      changeset: Accounts.build_user()
    )
  end

  def create(conn, %{"user" => attrs}) do
    case Accounts.create_user(attrs) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created.")
        |> redirect(to: ~p"/admin/users/#{user.id}")

      {:error, changeset} ->
        render(conn, :new, page_title: "New user", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    render(conn, :edit,
      page_title: "Edit #{user.username || user.id}",
      user: user,
      changeset: Accounts.change_user(user, %{}, :admin)
    )
  end

  def update(conn, %{"id" => id, "user" => attrs}) do
    user = Accounts.get_user!(id)

    with :ok <- check_admin_change(conn, user, attrs),
         {:ok, user} <- Asciinema.update_user(user, attrs, :admin) do
      conn
      |> put_flash(:info, "User updated.")
      |> redirect(to: ~p"/admin/users/#{user.id}")
    else
      {:error, message} when is_binary(message) ->
        conn
        |> put_flash(:error, message)
        |> render_edit(user, Accounts.change_user(user, %{}, :admin))

      {:error, changeset} ->
        render_edit(conn, user, changeset)
    end
  end

  defp render_edit(conn, user, changeset) do
    render(conn, :edit,
      page_title: "Edit #{user.username || user.id}",
      user: user,
      changeset: changeset
    )
  end

  # An admin can't strip their own admin access and footgun themselves out of the
  # panel. Only reachable on the main endpoint, where there's a current user.
  defp check_admin_change(conn, user, attrs) do
    cond do
      not removing_admin?(user, attrs) -> :ok
      own_account?(conn, user) -> {:error, "You can't remove your own admin access."}
      true -> :ok
    end
  end

  defp removing_admin?(%{is_admin: true}, %{"is_admin" => value}), do: value in [false, "false"]
  defp removing_admin?(_user, _attrs), do: false

  defp own_account?(conn, user) do
    case conn.assigns[:current_user] do
      %{id: id} -> id == user.id
      _ -> false
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    :ok = Asciinema.delete_user!(user)

    conn
    |> put_flash(:info, "User ##{user.id} deleted.")
    |> redirect(to: ~p"/admin/users")
  end

  def merge_confirm(conn, %{"id" => id} = params) do
    src = Accounts.get_user!(id)

    case resolve_target(params["target"], src) do
      {:ok, dst} ->
        render(conn, :merge_confirm,
          page_title: "Merge user",
          src: src,
          dst: dst,
          src_recording_count: user_recording_count(src.id),
          src_stream_count: user_stream_count(src.id),
          src_cli_count: length(Accounts.list_clis(src)),
          dst_recording_count: user_recording_count(dst.id),
          dst_stream_count: user_stream_count(dst.id),
          dst_cli_count: length(Accounts.list_clis(dst))
        )

      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: ~p"/admin/users/#{src.id}")
    end
  end

  def merge(conn, %{"id" => id, "target" => target}) do
    src = Accounts.get_user!(id)

    case resolve_target(target, src) do
      {:ok, dst} ->
        {:ok, merged} = Asciinema.merge_accounts(src, dst)

        conn
        |> put_flash(
          :info,
          "Merged #{src.username || src.id} into #{merged.username || merged.id}."
        )
        |> redirect(to: ~p"/admin/users/#{merged.id}")

      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: ~p"/admin/users/#{src.id}")
    end
  end

  defp resolve_target(nil, _src), do: {:error, "Enter a target user (id, username, or email)."}

  defp resolve_target(target, src) do
    target = String.trim(target)

    if target == "" do
      {:error, "Enter a target user (id, username, or email)."}
    else
      user =
        case Integer.parse(target) do
          {id, ""} -> Accounts.get_user(id)
          _ -> Accounts.find_user(target)
        end

      cond do
        is_nil(user) -> {:error, "Target user not found: #{target}"}
        user.id == src.id -> {:error, "Source and destination must differ."}
        true -> {:ok, user}
      end
    end
  end

  defp user_recording_count(user_id) do
    Recordings.count(%RecordingQuery{scope: :admin, archived: :include, filters: [user: user_id]})
  end

  defp user_stream_count(user_id) do
    Streaming.count(%StreamQuery{scope: :admin, filters: [user: user_id]})
  end
end
