defmodule AsciinemaAdmin.UserController do
  use AsciinemaAdmin, :controller

  alias Asciinema.{Accounts, Recordings, Repo, Streaming}
  alias Asciinema.Accounts.User
  alias Asciinema.Recordings.Query, as: RecordingQuery
  alias Asciinema.Streaming.Query, as: StreamQuery

  @page_size 50

  def index(conn, params) do
    search = params["q"] || ""
    sort_by = parse_sort_by(params["sort_by"])
    sort_dir = parse_sort_dir(params["sort_dir"])

    page =
      Accounts.list_users(
        search: search,
        sort_by: sort_by,
        sort_dir: sort_dir,
        page: params["page"],
        page_size: @page_size
      )

    filter_params =
      Map.reject(%{q: search, sort_by: sort_by, sort_dir: sort_dir}, fn {_k, v} -> v == "" end)

    render(conn, :index,
      page_title: "Users",
      users: page.entries,
      page: page,
      search: search,
      filter_params: filter_params,
      sort_by: sort_by,
      sort_dir: sort_dir
    )
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get!(User, id)
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
    user = Repo.get!(User, id)

    render(conn, :edit,
      page_title: "Edit #{user.username || user.id}",
      user: user,
      changeset: Accounts.change_user(user, %{}, :admin)
    )
  end

  def update(conn, %{"id" => id, "user" => attrs}) do
    user = Repo.get!(User, id)

    case Asciinema.update_user(user, attrs, :admin) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated.")
        |> redirect(to: ~p"/admin/users/#{user.id}")

      {:error, changeset} ->
        render(conn, :edit,
          page_title: "Edit #{user.username || user.id}",
          user: user,
          changeset: changeset
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Repo.get!(User, id)
    :ok = Asciinema.delete_user!(user)

    conn
    |> put_flash(:info, "User ##{user.id} deleted.")
    |> redirect(to: ~p"/admin/users")
  end

  def merge_confirm(conn, %{"id" => id} = params) do
    src = Repo.get!(User, id)

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
    src = Repo.get!(User, id)

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

    cond do
      target == "" ->
        {:error, "Enter a target user (id, username, or email)."}

      true ->
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

  defp parse_sort_by("last_login_at"), do: :last_login_at
  defp parse_sort_by(_), do: :inserted_at

  defp parse_sort_dir("asc"), do: :asc
  defp parse_sort_dir(_), do: :desc

  defp user_recording_count(user_id) do
    Recordings.count(%RecordingQuery{scope: :admin, archived: :include, filters: [user: user_id]})
  end

  defp user_stream_count(user_id) do
    Streaming.count(%StreamQuery{scope: :admin, filters: [user: user_id]})
  end
end
