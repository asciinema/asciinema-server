defmodule AsciinemaWeb.RecordingController do
  use AsciinemaWeb, :controller
  alias Asciinema.{FileStore, Recordings, PngGenerator}
  alias Asciinema.Recordings.Asciicast
  alias AsciinemaWeb.{Authorization, PlayerOpts, RecordingHTML}
  alias AsciinemaWeb.FallbackController

  plug :require_current_user when action in [:edit, :update, :delete]
  plug :load_and_authorize_asciicast when action in [:show, :edit, :update, :delete, :iframe]
  plug :redirect_to_canonical_path when action == :show

  def show(conn, _params) do
    do_show(conn, get_format(conn), conn.assigns.asciicast)
  end

  def do_show(conn, "html", asciicast) do
    if asciicast.archived_at do
      conn
      |> put_status(410)
      |> render(:deleted, ttl: Asciinema.unclaimed_recording_ttl())
    else
      current_user = conn.assigns.current_user
      self = !!(current_user && current_user.id == asciicast.user_id)
      other_asciicasts = fetch_other_asciicasts(asciicast, current_user)

      render(conn, :show,
        page_title: Recordings.title(asciicast),
        asciicast: asciicast,
        self: self,
        player_opts: player_opts(conn.params),
        actions: asciicast_actions(asciicast, current_user),
        view_count_url: build_view_count_url(conn, asciicast),
        other_asciicasts: other_asciicasts
      )
    end
  end

  def do_show(conn, format, asciicast) when format in ["json", "cast"] do
    if asciicast.archived_at do
      send_resp(conn, 410, "")
    else
      filename = download_filename(asciicast, conn.params)

      conn
      |> put_resp_header("access-control-allow-origin", "*")
      |> FileStore.serve_file(asciicast.path, filename)
    end
  end

  @js_max_age 60

  def do_show(conn, "js", _asciicast) do
    path = Application.app_dir(:asciinema, "priv/static/js/embed.js")

    conn
    |> put_resp_content_type("application/javascript")
    |> put_resp_header("cache-control", "public, max-age=#{@js_max_age}")
    |> send_file(200, path)
  end

  def do_show(conn, "txt", asciicast) do
    if asciicast.archived_at do
      conn
      |> put_status(410)
      |> text("This recording has been deleted\n")
    else
      send_download(conn, {:file, Recordings.text_file_path(asciicast)},
        filename: "#{asciicast.id}.txt"
      )
    end
  end

  # 1 hour
  @svg_max_age 3600

  def do_show(conn, "svg", asciicast) do
    if asciicast.archived_at do
      path = Application.app_dir(:asciinema, "priv/static/images/archived.png")

      conn
      |> put_status(410)
      |> put_resp_content_type("image/png")
      |> send_file(200, path)
    else
      conn =
        conn
        |> put_resp_header("cache-control", "public, max-age=#{@svg_max_age}, must-revalidate")
        |> put_etag(RecordingHTML.svg_cache_key(asciicast))
        |> put_resp_header("access-control-allow-origin", "*")

      case conn.params["f"] do
        "t" -> render(conn, :thumbnail, asciicast: asciicast, standalone: true)
        _ -> render(conn, :show, asciicast: asciicast)
      end
    end
  end

  # 7 days
  @png_max_age 604_800

  def do_show(conn, "png", asciicast) do
    if asciicast.archived_at do
      path = Application.app_dir(:asciinema, "priv/static/images/archived.png")

      conn
      |> put_status(410)
      |> put_resp_content_type("image/png")
      |> send_file(200, path)
    else
      case PngGenerator.generate(asciicast) do
        {:ok, png_path} ->
          conn
          |> put_resp_content_type(MIME.from_path(png_path))
          |> put_resp_header("cache-control", "public, max-age=#{@png_max_age}")
          |> send_file(200, png_path)
          |> halt()

        {:error, :busy} ->
          conn
          |> put_resp_header("retry-after", "5")
          |> send_resp(503, "")
      end
    end
  end

  def do_show(conn, "gif", asciicast) do
    if asciicast.archived_at do
      send_resp(conn, 410, "")
    else
      conn
      |> put_layout("simple.html")
      |> render("gif.html",
        file_url: asciicast_file_url(asciicast),
        asciicast_id: asciicast.id
      )
    end
  end

  defp fetch_other_asciicasts(asciicast, current_user) do
    [user_id: asciicast.user_id, id: {:not_eq, asciicast.id}]
    |> Recordings.query(:random)
    |> Authorization.scope(:asciicasts, current_user)
    |> list_asciicasts(4)
  end

  defp list_asciicasts(query, limit) do
    items = Recordings.list(query, limit + 1)

    %{
      items: Enum.take(items, limit),
      has_more: length(items) > limit
    }
  end

  def edit(conn, _params) do
    changeset = Recordings.change_asciicast(conn.assigns.asciicast)
    render_edit_form(conn, changeset)
  end

  def update(conn, %{"asciicast" => asciicast_params}) do
    asciicast = conn.assigns.asciicast

    case Recordings.update_asciicast(asciicast, asciicast_params) do
      {:ok, asciicast} ->
        conn
        |> put_flash(:info, "Recording updated.")
        |> redirect(to: ~p"/a/#{asciicast}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render_edit_form(conn, changeset)
    end
  end

  defp render_edit_form(conn, changeset) do
    render(conn, "edit.html", changeset: changeset, instance_url: AsciinemaWeb.Endpoint.url())
  end

  def delete(conn, _params) do
    asciicast = conn.assigns.asciicast

    case Recordings.delete_asciicast(asciicast) do
      {:ok, _asciicast} ->
        conn
        |> put_flash(:info, "Recording deleted.")
        |> redirect(to: ~p"/~#{conn.assigns.current_user}")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Couldn't remove this recording.")
        |> redirect(to: ~p"/a/#{asciicast}")
    end
  end

  def iframe(conn, params) do
    conn =
      conn
      |> put_layout("iframe.html")
      |> delete_resp_header("x-frame-options")

    if conn.assigns.asciicast.archived_at do
      conn
      |> put_status(410)
      |> render("deleted.html", ttl: Asciinema.unclaimed_recording_ttl())
    else
      render(conn, "iframe.html", player_opts: player_opts(params))
    end
  end

  defp download_filename(%Asciicast{version: version, id: id}, %{"dl" => _}) do
    case version do
      0 -> "#{id}.json"
      1 -> "#{id}.json"
      2 -> "#{id}.cast"
      3 -> "#{id}.cast"
    end
  end

  defp download_filename(_asciicast, _params) do
    nil
  end

  defp load_and_authorize_asciicast(conn, _) do
    id = String.trim(conn.params["id"])

    case Recordings.lookup_asciicast(id, load_snapshot: true) do
      nil ->
        conn
        |> FallbackController.call({:error, :not_found})
        |> halt()

      asciicast ->
        user = conn.assigns[:current_user]
        action = Phoenix.Controller.action_name(conn)

        if Authorization.can?(user, action, asciicast) do
          assign(conn, :asciicast, asciicast)
        else
          status = if Recordings.secret_token?(id), do: :forbidden, else: :not_found

          conn
          |> FallbackController.call({:error, status})
          |> halt()
        end
    end
  end

  defp redirect_to_canonical_path(conn, _) do
    id = String.trim(conn.params["id"])
    asciicast = conn.assigns.asciicast

    if get_format(conn) == "html" && id != Phoenix.Param.to_param(asciicast) do
      conn
      |> redirect(to: ~p"/a/#{asciicast}")
      |> halt()
    else
      conn
    end
  end

  @actions [:edit, :delete]

  defp asciicast_actions(asciicast, user) do
    Enum.filter(@actions, &Authorization.can?(user, &1, asciicast))
  end

  defp player_opts(params) do
    params
    |> Ext.Map.rename(%{"t" => "startAt", "i" => "idleTimeLimit"})
    |> PlayerOpts.parse(:recording)
  end

  defp build_view_count_url(conn, asciicast) do
    case conn.req_cookies["a#{asciicast.id}"] do
      nil ->
        token = Recordings.generate_view_count_token(asciicast.id)
        ~p"/a/#{asciicast}/views?token=#{token}"

      _ ->
        nil
    end
  end
end
