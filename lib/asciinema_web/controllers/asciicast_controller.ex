defmodule AsciinemaWeb.AsciicastController do
  use AsciinemaWeb, :controller
  alias Asciinema.{Asciicasts, PngGenerator, Accounts}
  alias Asciinema.Asciicasts.Asciicast

  plug :put_layout, "app2.html"
  plug :clear_main_class
  plug :load_asciicast when action in [:show, :edit, :update, :delete, :example, :iframe, :embed]
  plug :require_current_user when action in [:edit, :update, :delete]
  plug :authorize, :asciicast when action in [:edit, :update, :delete]

  def index(conn, _params) do
    redirect(conn, to: Routes.asciicast_path(conn, :category, :featured))
  end

  def category(conn, %{"category" => c} = params) when c in ["featured", "public"] do
    category = String.to_existing_atom(c)
    order = if params["order"] == "popularity", do: :popularity, else: :date

    page = Asciicasts.paginate_asciicasts(category, order, params["page"], 12)

    assigns = [
      page_title: String.capitalize("#{category} asciicasts"),
      category: category,
      page: page,
      order: order
    ]

    render(conn, "category.html", assigns)
  end

  def category(conn, _params) do
    redirect(conn, to: Routes.asciicast_path(conn, :category, :featured))
  end

  def show(conn, _params) do
    do_show(conn, get_format(conn), conn.assigns.asciicast)
  end

  def do_show(conn, "html", asciicast) do
    if asciicast.archived_at do
      conn
      |> put_status(410)
      |> render("archived.html")
    else
      conn
      |> count_view(asciicast)
      |> put_archival_info_flash(asciicast)
      |> render(
        "show.html",
        page_title: AsciinemaWeb.AsciicastView.title(asciicast),
        asciicast: asciicast,
        playback_options: Asciicasts.PlaybackOpts.parse(conn.params),
        actions: asciicast_actions(asciicast, conn.assigns.current_user),
        author_asciicasts: Asciicasts.other_public_asciicasts(asciicast)
      )
    end
  end

  def do_show(conn, format, asciicast) when format in ["json", "cast"] do
    if asciicast.archived_at do
      send_resp(conn, 410, "")
    else
      path = Asciicast.json_store_path(asciicast)
      filename = download_filename(asciicast, conn.params)

      conn
      |> put_resp_header("access-control-allow-origin", "*")
      |> file_store().serve_file(path, filename)
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

  def do_show(conn, "svg", asciicast) do
    if asciicast.archived_at do
      path = Application.app_dir(:asciinema, "priv/static/images/archived.png")

      conn
      |> put_status(410)
      |> put_resp_header("content-type", "image/png")
      |> send_file(200, path)
    else
      render(conn, "show.svg", asciicast: asciicast)
    end
  end

  @png_max_age 604_800 # 7 days

  def do_show(conn, "png", asciicast) do
    if asciicast.archived_at do
      path = Application.app_dir(:asciinema, "priv/static/images/archived.png")

      conn
      |> put_status(410)
      |> put_resp_header("content-type", "image/png")
      |> send_file(200, path)
    else
      case PngGenerator.generate(asciicast) do
        {:ok, png_path} ->
          conn
          |> put_resp_header("content-type", MIME.from_path(png_path))
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
      |> render("gif.html", file_url: asciicast_file_url(conn, asciicast))
    end
  end

  def edit(conn, _params) do
    changeset = Asciicasts.change_asciicast(conn.assigns.asciicast)
    render(conn, "edit.html", changeset: changeset)
  end

  def update(conn, %{"asciicast" => asciicast_params}) do
    asciicast = conn.assigns.asciicast

    case Asciicasts.update_asciicast(asciicast, asciicast_params) do
      {:ok, asciicast} ->
        conn
        |> put_flash(:info, "Asciicast updated.")
        |> redirect(to: Routes.asciicast_path(conn, :show, asciicast))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  def delete(conn, _params) do
    asciicast = conn.assigns.asciicast

    case Asciicasts.delete_asciicast(asciicast) do
      {:ok, _asciicast} ->
        conn
        |> put_flash(:info, "Asciicast deleted.")
        |> redirect(to: profile_path(conn, conn.assigns.current_user))

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Oops, couldn't remove this asciicast.")
        |> redirect(to: Routes.asciicast_path(conn, :show, asciicast))
    end
  end

  def iframe(conn, _params) do
    conn =
      conn
      |> put_layout("iframe.html")
      |> delete_resp_header("x-frame-options")

    if conn.assigns.asciicast.archived_at do
      conn
      |> put_status(410)
      |> render("archived.html")
    else
      url = asciicast_file_url(conn, conn.assigns.asciicast)
      render(conn, "iframe.html", file_url: url)
    end
  end

  def embed(conn, params) do
    opts = Asciicasts.PlaybackOpts.parse(params)
    conn =
      conn
      |> put_layout("embed.html")
      |> delete_resp_header("x-frame-options")

    if conn.assigns.asciicast.archived_at do
      conn
      |> put_status(410)
      |> render("archived.html")
    else
      render(conn, "embed.html", playback_options: opts)
    end
  end

  def example(conn, _params) do
    home_asciicast = Asciicasts.get_homepage_asciicast()

    conn
    |> put_layout("example.html")
    |> render("example.html", home_asciicast: home_asciicast)
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
    case Asciicasts.fetch_asciicast(conn.params["id"]) do
      {:ok, asciicast} ->
        assign(conn, :asciicast, asciicast)

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
        Asciicasts.inc_views_count(asciicast)
        put_resp_cookie(conn, key, "1", max_age: 3600*24)

      _ ->
        conn
    end
  end

  @actions [
    :edit, :delete,
    :make_private, :make_public,
    :make_featured, :make_not_featured
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

  defp put_archival_info_flash(conn, asciicast) do
    with true <- asciicast.archivable,
         days when not is_nil(days) <- Asciicasts.gc_days(),
         %{} = user <- asciicast.user,
         true <- Accounts.temporary_user?(user),
         true <- Timex.before?(asciicast.created_at, Timex.shift(Timex.now(), days: -days)) do
      put_flash(conn, :error, {:safe, "This recording will be archived soon. More details: <a href=\"https://blog.asciinema.org/post/archival/\">blog.asciinema.org/post/archival/</a>"})
    else
      _ -> conn
    end
  end
end
