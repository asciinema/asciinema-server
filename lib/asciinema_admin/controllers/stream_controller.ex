defmodule AsciinemaAdmin.StreamController do
  use AsciinemaAdmin, :controller

  alias Asciinema.{Recordings, Repo, Streaming}
  alias Asciinema.Recordings.Query, as: RecordingQuery
  alias Asciinema.Streaming.Stream
  alias AsciinemaAdmin.StreamHTML

  @page_size 50
  @recordings_limit 15

  def index(conn, params) do
    search = params["q"] || ""
    visibility = parse_visibility(params["visibility"])
    live = parse_tristate(params["live"])
    sort_by = parse_sort_by(params["sort_by"])
    sort_dir = parse_sort_dir(params["sort_dir"])

    page =
      Streaming.list_streams_admin(
        search: search,
        visibility: visibility,
        live: live,
        sort_by: sort_by,
        sort_dir: sort_dir,
        page: params["page"],
        page_size: @page_size
      )

    filter_params =
      Map.reject(
        %{q: search, visibility: visibility, live: live, sort_by: sort_by, sort_dir: sort_dir},
        fn {_k, v} -> v in ["", :all] end
      )

    render(conn, :index,
      page_title: "Streams",
      streams: page.entries,
      page: page,
      search: search,
      visibility: visibility,
      live: live,
      filter_params: filter_params,
      sort_by: sort_by,
      sort_dir: sort_dir
    )
  end

  def show(conn, %{"id" => id}) do
    stream = Repo.get!(Stream, id) |> Repo.preload(:user)
    recordings_query = stream_recordings_query(stream.id)

    render(conn, :show,
      page_title: stream.title || "Stream ##{stream.id}",
      stream: stream,
      player_src: StreamHTML.player_src(stream),
      recordings: Recordings.list(recordings_query, @recordings_limit, preload: [:user]),
      recording_count: Recordings.count(recordings_query)
    )
  end

  defp stream_recordings_query(stream_id) do
    %RecordingQuery{
      scope: :admin,
      archived: :include,
      filters: [stream: stream_id],
      sort: {:created, :desc}
    }
  end

  def edit(conn, %{"id" => id}) do
    stream = Repo.get!(Stream, id) |> Repo.preload(:user)

    render(conn, :edit,
      page_title: "Edit stream ##{stream.id}",
      stream: stream,
      changeset: Streaming.change_stream(stream)
    )
  end

  def update(conn, %{"id" => id, "stream" => attrs}) do
    stream = Repo.get!(Stream, id) |> Repo.preload(:user)

    case Streaming.update_stream(stream, attrs) do
      {:ok, stream} ->
        conn
        |> put_flash(:info, "Stream updated.")
        |> redirect(to: ~p"/admin/streams/#{stream.id}")

      {:error, changeset} ->
        render(conn, :edit,
          page_title: "Edit stream ##{stream.id}",
          stream: stream,
          changeset: changeset
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    stream = Repo.get!(Stream, id)
    {:ok, _} = Streaming.delete_stream(stream)

    conn
    |> put_flash(:info, "Stream ##{stream.id} deleted.")
    |> redirect(to: ~p"/admin/streams")
  end

  def disconnect(conn, %{"id" => id}) do
    stream = Repo.get!(Stream, id)

    case Streaming.disconnect_stream(stream) do
      :ok ->
        conn
        |> put_flash(:info, "Stream disconnected.")
        |> redirect(to: ~p"/admin/streams/#{stream.id}")

      {:error, :not_running} ->
        conn
        |> put_flash(:info, "Stream was not running.")
        |> redirect(to: ~p"/admin/streams/#{stream.id}")
    end
  end

  defp parse_visibility("public"), do: :public
  defp parse_visibility("unlisted"), do: :unlisted
  defp parse_visibility("private"), do: :private
  defp parse_visibility(_), do: :all

  defp parse_tristate("yes"), do: true
  defp parse_tristate("true"), do: true
  defp parse_tristate("no"), do: false
  defp parse_tristate("false"), do: false
  defp parse_tristate(_), do: :all

  defp parse_sort_by("current_viewer_count"), do: :current_viewer_count
  defp parse_sort_by("peak_viewer_count"), do: :peak_viewer_count
  defp parse_sort_by("inserted_at"), do: :inserted_at
  defp parse_sort_by(_), do: :last_started_at

  defp parse_sort_dir("asc"), do: :asc
  defp parse_sort_dir(_), do: :desc
end
