defmodule AsciinemaWeb.LiveStreamController do
  use AsciinemaWeb, :new_controller
  alias Asciinema.{Authorization, Recordings, Streaming}
  alias AsciinemaWeb.PlayerOpts

  plug :clear_main_class
  plug :load_stream when action in [:show, :edit, :update]
  plug :require_current_user when action in [:edit, :update]
  plug :authorize, :stream when action in [:edit, :update]

  def show(conn, params) do
    stream = conn.assigns.stream
    current_user = conn.assigns.current_user
    user_is_self = match?({%{id: id}, %{id: id}}, {current_user, stream.user})

    render(
      conn,
      :show,
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

  @actions [
    :edit,
    :make_private,
    :make_public
  ]

  defp stream_actions(stream, user) do
    @actions
    |> Enum.filter(&action_applicable?(&1, stream))
    |> Enum.filter(&Authorization.can?(user, &1, stream))
  end

  defp action_applicable?(action, stream) do
    case action do
      :edit -> true
      :make_private -> !stream.private
      :make_public -> stream.private
    end
  end

  defp load_stream(conn, _) do
    case Streaming.fetch_live_stream(conn.params["id"]) do
      {:ok, stream} ->
        assign(conn, :stream, stream)

      {:error, :not_found} ->
        conn
        |> AsciinemaWeb.FallbackController.call({:error, :not_found})
        |> halt()
    end
  end
end
