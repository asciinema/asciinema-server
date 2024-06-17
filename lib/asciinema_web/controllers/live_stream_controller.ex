defmodule AsciinemaWeb.LiveStreamController do
  use AsciinemaWeb, :controller
  alias Asciinema.{Authorization, Recordings, Streaming}
  alias AsciinemaWeb.{FallbackController, LiveStreamHTML, PlayerOpts}

  plug :load_stream when action in [:show, :edit, :update]
  plug :require_current_user_when_private when action == :show
  plug :require_current_user when action in [:edit, :update]
  plug :authorize, :stream when action in [:show, :edit, :update]

  def show(conn, params) do
    stream = conn.assigns.stream
    current_user = conn.assigns.current_user
    user_is_self = match?({%{id: id}, %{id: id}}, {current_user, stream.user})

    render(
      conn,
      :show,
      page_title: LiveStreamHTML.title(stream),
      player_opts: player_opts(params),
      actions: stream_actions(stream, current_user),
      user_is_self: user_is_self,
      author_asciicasts: Recordings.list_public_asciicasts(stream.user)
    )
  end

  def edit(conn, _params) do
    changeset = Streaming.change_live_stream(conn.assigns.stream)
    render(conn, :edit, changeset: changeset)
  end

  def update(conn, %{"live_stream" => params}) do
    case Streaming.update_live_stream(conn.assigns.stream, params) do
      {:ok, stream} ->
        conn
        |> put_flash(:info, "Live stream updated.")
        |> redirect(to: ~p"/s/#{stream}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, changeset: changeset)
    end
  end

  defp player_opts(params) do
    PlayerOpts.parse(params, :live_stream)
  end

  defp stream_actions(stream, user) do
    if Authorization.can?(user, :edit, stream) do
      [:edit]
    else
      []
    end
  end

  defp load_stream(conn, _) do
    case Streaming.fetch_live_stream(conn.params["id"]) do
      {:ok, stream} ->
        assign(conn, :stream, stream)

      {:error, :not_found} ->
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
end
