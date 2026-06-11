defmodule AsciinemaAdmin.RecordingController do
  use AsciinemaAdmin, :controller

  alias Asciinema.{Recordings, Repo, Zstd}
  alias Asciinema.Recordings.Asciicast
  alias AsciinemaAdmin.{IndexQuery, RecordingHTML}

  @page_size 50
  @cast_chunk_size 64 * 1024

  def index(conn, params) do
    index = IndexQuery.build(:recordings, params)

    page =
      if index.valid? do
        Recordings.paginate(index.query, params["page"], @page_size,
          preload: [:user],
          with_total_views: true
        )
      else
        IndexQuery.empty_page(params["page"], @page_size)
      end

    render(conn, :index,
      page_title: "Recordings",
      recordings: page.entries,
      page: page,
      index: index,
      filter_params: index.query_params
    )
  end

  def show(conn, %{"id" => id}) do
    asciicast =
      case Recordings.get_asciicast(id, load_snapshot: true) do
        nil -> raise Ecto.NoResultsError, queryable: Asciicast
        a -> a
      end

    render(conn, :show,
      page_title: asciicast.title || "Recording ##{asciicast.id}",
      asciicast: asciicast,
      player_src: RecordingHTML.player_src(asciicast),
      player_opts: RecordingHTML.player_opts(asciicast)
    )
  end

  @doc """
  Serves the cast file same-origin, sidestepping the public endpoint's
  visibility checks so the player reaches private recordings.
  """
  def cast_file(conn, %{"id" => id}) do
    asciicast = Repo.get!(Asciicast, id)
    {:ok, path} = Recordings.fetch_cast_path(asciicast)

    conn =
      conn
      |> put_resp_header("content-type", "application/x-asciicast")
      |> put_resp_header("cache-control", "no-store")

    # remote/S3 files are cached without a .zst suffix, hence the schema flag
    if asciicast.compressed do
      conn = send_chunked(conn, 200)

      path
      |> Zstd.stream!(@cast_chunk_size)
      |> Enum.reduce_while(conn, fn data, conn ->
        case chunk(conn, data) do
          {:ok, conn} -> {:cont, conn}
          {:error, _} -> {:halt, conn}
        end
      end)
    else
      send_file(conn, 200, path)
    end
  end

  def edit(conn, %{"id" => id}) do
    asciicast = Repo.get!(Asciicast, id) |> Repo.preload(:user)

    render(conn, :edit,
      page_title: "Edit recording ##{asciicast.id}",
      asciicast: asciicast,
      changeset: Recordings.change_asciicast(asciicast)
    )
  end

  def update(conn, %{"id" => id, "asciicast" => attrs}) do
    asciicast = Repo.get!(Asciicast, id) |> Repo.preload(:user)

    case Recordings.update_asciicast(asciicast, attrs) do
      {:ok, asciicast} ->
        conn
        |> put_flash(:info, "Recording updated.")
        |> redirect(to: ~p"/admin/recordings/#{asciicast.id}")

      {:error, changeset} ->
        render(conn, :edit,
          page_title: "Edit recording ##{asciicast.id}",
          asciicast: asciicast,
          changeset: changeset
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    asciicast = Repo.get!(Asciicast, id)
    {:ok, _} = Recordings.delete_asciicast(asciicast)

    conn
    |> put_flash(:info, "Recording ##{asciicast.id} deleted.")
    |> redirect(to: ~p"/admin/recordings")
  end

  def set_visibility(conn, %{"id" => id, "visibility" => vis}) do
    asciicast = Repo.get!(Asciicast, id)

    case Recordings.update_asciicast(asciicast, %{visibility: vis}) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Visibility set to #{vis}.")
        |> redirect(to: ~p"/admin/recordings/#{asciicast.id}")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Could not update visibility.")
        |> redirect(to: ~p"/admin/recordings/#{asciicast.id}")
    end
  end

  def set_featured(conn, %{"id" => id, "featured" => featured}) do
    asciicast = Repo.get!(Asciicast, id)
    val = featured == "true"

    case Recordings.set_featured(asciicast, val) do
      {:ok, _} ->
        conn
        |> put_flash(:info, if(val, do: "Featured.", else: "Unfeatured."))
        |> redirect(to: ~p"/admin/recordings/#{asciicast.id}")

      {:error, _} ->
        conn
        |> put_flash(:error, "Could not update featured flag.")
        |> redirect(to: ~p"/admin/recordings/#{asciicast.id}")
    end
  end

  def unarchive(conn, %{"id" => id}) do
    asciicast = Repo.get!(Asciicast, id)

    case Recordings.unarchive(asciicast) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Unarchived.")
        |> redirect(to: ~p"/admin/recordings/#{asciicast.id}")

      {:error, _} ->
        conn
        |> put_flash(:error, "Could not unarchive.")
        |> redirect(to: ~p"/admin/recordings/#{asciicast.id}")
    end
  end

  def archive_now(conn, %{"id" => id}) do
    asciicast = Repo.get!(Asciicast, id)

    case Recordings.archive_now(asciicast) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Archived.")
        |> redirect(to: ~p"/admin/recordings/#{asciicast.id}")

      {:error, _} ->
        conn
        |> put_flash(:error, "Could not archive.")
        |> redirect(to: ~p"/admin/recordings/#{asciicast.id}")
    end
  end
end
