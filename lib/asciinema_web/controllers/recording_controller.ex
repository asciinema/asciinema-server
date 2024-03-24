defmodule AsciinemaWeb.RecordingController do
  use AsciinemaWeb, :new_controller
  alias Asciinema.{Recordings, PngGenerator}
  alias Asciinema.Recordings.Asciicast
  alias AsciinemaWeb.PlayerOpts

  plug :clear_main_class
  plug :load_asciicast when action in [:show, :edit, :update, :delete, :iframe]
  plug :require_current_user when action in [:edit, :update, :delete]
  plug :authorize, :asciicast when action in [:edit, :update, :delete]

  def index(conn, params) do
    category = params[:category]
    order = if params["order"] == "popularity", do: :popularity, else: :date

    page = Recordings.paginate_asciicasts(category, order, params["page"], 14)

    assigns = [
      page_title: String.capitalize("#{category} recordings"),
      category: category,
      sidebar_hidden: params[:sidebar_hidden],
      page: page,
      order: order
    ]

    render(conn, "index.html", assigns)
  end

  def auto(conn, params) do
    case Recordings.count_featured_asciicasts() do
      0 ->
        index(conn, Map.merge(params, %{category: :public, sidebar_hidden: true}))

      _ ->
        index(conn, Map.put(params, :category, :featured))
    end
  end

  def public(conn, params) do
    index(conn, Map.put(params, :category, :public))
  end

  def featured(conn, params) do
    index(conn, Map.put(params, :category, :featured))
  end

  def show(conn, _params) do
    do_show(conn, get_format(conn), conn.assigns.asciicast)
  end

  def do_show(conn, "html", asciicast) do
    if asciicast.archived_at do
      conn
      |> put_status(410)
      |> render(:deleted, ttl: Asciinema.unclaimed_recording_ttl())
    else
      conn
      |> count_view(asciicast)
      |> render(
        :show,
        page_title: Recordings.title(asciicast),
        asciicast: asciicast,
        player_opts: player_opts(conn.params),
        actions: asciicast_actions(asciicast, conn.assigns.current_user),
        author_asciicasts: Recordings.list_other_public_asciicasts(asciicast)
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
      |> file_store().serve_file(asciicast.path, filename)
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

  def do_show(conn, "svg", asciicast) do
    if asciicast.archived_at do
      path = Application.app_dir(:asciinema, "priv/static/images/archived.png")

      conn
      |> put_status(410)
      |> put_resp_content_type("image/png")
      |> send_file(200, path)
    else
      case conn.params["v"] do
        "t" ->
          render(conn, :thumbnail, asciicast: asciicast)

        _ ->
          render(conn, :show, asciicast: asciicast)
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
          |> halt

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
        file_url: asciicast_file_url(conn, asciicast),
        asciicast_id: asciicast.id
      )
    end
  end

  def edit(conn, _params) do
    changeset = Recordings.change_asciicast(conn.assigns.asciicast)
    render(conn, "edit.html", changeset: changeset)
  end

  def update(conn, %{"asciicast" => asciicast_params}) do
    asciicast = conn.assigns.asciicast

    case Recordings.update_asciicast(asciicast, asciicast_params) do
      {:ok, asciicast} ->
        conn
        |> put_flash(:info, "Asciicast updated.")
        |> redirect(to: ~p"/a/#{asciicast}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  def delete(conn, _params) do
    asciicast = conn.assigns.asciicast

    case Recordings.delete_asciicast(asciicast) do
      {:ok, _asciicast} ->
        conn
        |> put_flash(:info, "Asciicast deleted.")
        |> redirect(to: profile_path(conn, conn.assigns.current_user))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Oops, couldn't remove this asciicast.")
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
    end
  end

  defp download_filename(_asciicast, _params) do
    nil
  end

  defp file_store do
    Application.get_env(:asciinema, :file_store)
  end

  defp load_asciicast(conn, _) do
    id = String.trim(conn.params["id"])

    case Recordings.fetch_asciicast(id) do
      {:ok, asciicast} ->
        public_id = to_string(asciicast.id)

        case {asciicast.private, action_name(conn), get_format(conn), id == public_id} do
          {false, :show, "html", false} ->
            conn
            |> redirect(to: ~p"/a/#{asciicast}")
            |> halt()

          _ ->
            assign(conn, :asciicast, asciicast)
        end

      {:error, :not_found} ->
        conn
        |> AsciinemaWeb.FallbackController.call({:error, :not_found})
        |> halt()
    end
  end

  defp count_view(conn, asciicast) do
    key = "a#{asciicast.id}"

    case conn.req_cookies[key] do
      nil ->
        Recordings.inc_views_count(asciicast)
        put_resp_cookie(conn, key, "1", max_age: 3600 * 24)

      _ ->
        conn
    end
  end

  @actions [
    :edit,
    :delete,
    :make_private,
    :make_public,
    :make_featured,
    :make_not_featured
  ]

  defp asciicast_actions(asciicast, user) do
    @actions
    |> Enum.filter(&action_applicable?(&1, asciicast))
    |> Enum.filter(&Asciinema.Authorization.can?(user, &1, asciicast))
  end

  defp action_applicable?(action, asciicast) do
    case action do
      :make_private -> !asciicast.private
      :make_public -> asciicast.private
      :make_featured -> !asciicast.featured
      :make_not_featured -> asciicast.featured
      _ -> true
    end
  end

  defp player_opts(params) do
    params
    |> Ext.Map.rename(%{"t" => "startAt", "i" => "idleTimeLimit"})
    |> PlayerOpts.parse(:recording)
  end
end
