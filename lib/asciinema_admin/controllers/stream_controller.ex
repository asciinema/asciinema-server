defmodule AsciinemaAdmin.StreamController do
  use AsciinemaAdmin, :controller

  alias Asciinema.{Recordings, Repo, Streaming}
  alias Asciinema.Recordings.Query, as: RecordingQuery
  alias Asciinema.Streaming.Stream
  alias AsciinemaAdmin.{IndexQuery, StreamHTML}

  @page_size 50
  @recordings_limit 15

  def index(conn, params) do
    index = IndexQuery.build(:streams, params)

    page =
      if index.valid? do
        Streaming.paginate(index.query, params["page"], @page_size, preload: [:user])
      else
        empty_page(params["page"])
      end

    render(conn, :index,
      page_title: "Streams",
      streams: page.entries,
      page: page,
      index: index,
      filter_params: index.query_params
    )
  end

  def show(conn, %{"id" => id}) do
    stream = Repo.get!(Stream, id) |> Repo.preload(:user)
    recordings_query = stream_recordings_query(stream.id)

    render(conn, :show,
      page_title: stream.title || "Stream ##{stream.id}",
      stream: stream,
      player_src: StreamHTML.player_src(stream),
      player_opts: StreamHTML.player_opts(stream),
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

  defp empty_page(page) do
    %Scrivener.Page{
      entries: [],
      page_number: page_number(page),
      page_size: @page_size,
      total_entries: 0,
      total_pages: 0
    }
  end

  defp page_number(page) when is_binary(page) do
    case Integer.parse(page) do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end

  defp page_number(_), do: 1
end
