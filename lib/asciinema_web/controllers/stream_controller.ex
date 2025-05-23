defmodule AsciinemaWeb.StreamController do
  use AsciinemaWeb, :controller
  import AsciinemaWeb.Plug.ReturnTo
  alias Asciinema.Authorization
  alias Asciinema.{Authorization, Recordings, Streaming}
  alias AsciinemaWeb.{FallbackController, StreamHTML, PlayerOpts}

  plug :load_stream when action in [:show, :edit, :update, :delete]
  plug :require_current_user_when_private when action == :show
  plug :require_current_user when action in [:index, :create, :edit, :update, :delete]
  plug :authorize, :stream when action in [:show, :edit, :update, :delete]
  plug :check_streaming_enabled when action in [:index, :edit, :update, :start]

  def index(conn, params) do
    current_user = conn.assigns.current_user

    streams =
      [user_id: current_user.id]
      |> Streaming.query(:activity)
      |> Streaming.paginate(params["page"], 25)

    stream_ids = Enum.map(streams, & &1.id)

    rec_count_by_stream_id =
      [user_id: current_user.id, stream_id: {:in, stream_ids}]
      |> Recordings.query()
      |> Recordings.count_by(:stream_id)

    render(conn, "index.html",
      streams: streams,
      rec_count_by_stream_id: rec_count_by_stream_id
    )
  end

  def create(conn, _params) do
    case Streaming.create_stream(conn.assigns.current_user) do
      {:ok, stream} ->
        id = Streaming.short_public_token(stream)

        conn
        |> put_flash(:info, "Stream #{id} created.")
        |> redirect(to: ~p"/user/streams")

      {:error, :limit_reached} ->
        conn
        |> put_flash(:error, "Stream limit reached. Contact admin to raise the limit.")
        |> redirect(to: ~p"/user/streams")
    end
  end

  def show(conn, params) do
    stream = conn.assigns.stream
    current_user = conn.assigns.current_user
    user_is_self = match?({%{id: id}, %{id: id}}, {current_user, stream.user})

    stream_asciicasts =
      [user_id: stream.user_id, stream_id: stream.id]
      |> Recordings.query(:date)
      |> Authorization.scope(:asciicasts, current_user)
      |> Recordings.list(4)

    other_asciicasts =
      [user_id: stream.user_id, stream_id: {:not_eq, stream.id}]
      |> Recordings.query(:random)
      |> Authorization.scope(:asciicasts, current_user)
      |> Recordings.list(4)

    render(
      conn,
      :show,
      page_title: StreamHTML.title(stream),
      player_opts: player_opts(params),
      actions: stream_actions(stream, current_user),
      user_is_self: user_is_self,
      stream_asciicasts: stream_asciicasts,
      other_asciicasts: other_asciicasts
    )
  end

  def edit(conn, params) do
    conn =
      if ret = params["ret"] do
        save_return_path(conn, ret)
      else
        conn
      end

    changeset = Streaming.change_stream(conn.assigns.stream)
    render(conn, :edit, changeset: changeset)
  end

  def update(conn, %{"stream" => params}) do
    case Streaming.update_stream(conn.assigns.stream, params) do
      {:ok, stream} ->
        id = Streaming.short_public_token(stream)

        conn
        |> put_flash(:info, "Stream #{id} updated.")
        |> redirect_back_or(to: ~p"/s/#{stream}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, changeset: changeset)
    end
  end

  def delete(conn, params) do
    stream = conn.assigns.stream

    case Streaming.delete_stream(stream) do
      {:ok, stream} ->
        id = Streaming.short_public_token(stream)

        conn
        |> put_flash(:info, "Stream #{id} deleted.")
        |> redirect(to: ~p"/user/streams")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Couldn't remove this stream.")
        |> redirect(to: params["ret"] || ~p"/s/#{stream}")
    end
  end

  defp player_opts(params) do
    PlayerOpts.parse(params, :stream)
  end

  @actions [:edit, :delete]

  defp stream_actions(stream, user) do
    Enum.filter(@actions, &Asciinema.Authorization.can?(user, &1, stream))
  end

  defp load_stream(conn, _) do
    with stream when not is_nil(stream) <- Streaming.get_stream(conn.params["id"]),
         true <- stream.user.streaming_enabled do
      assign(conn, :stream, stream)
    else
      _ ->
        conn
        |> FallbackController.call({:error, :not_found})
        |> halt()
    end
  end

  defp require_current_user_when_private(conn, _opts) do
    if conn.assigns.stream.visibility == :private do
      require_current_user(conn, [])
    else
      conn
    end
  end

  defp check_streaming_enabled(conn, _opts) do
    if conn.assigns.current_user.streaming_enabled do
      conn
    else
      conn
      |> put_flash(:error, "Streaming is disabled for your account.")
      |> redirect(to: ~p"/")
      |> halt()
    end
  end
end
