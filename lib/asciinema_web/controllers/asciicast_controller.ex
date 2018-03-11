defmodule AsciinemaWeb.AsciicastController do
  use AsciinemaWeb, :controller
  alias Asciinema.{Asciicasts, PngGenerator}
  alias Asciinema.Asciicasts.Asciicast

  def show(conn, %{"id" => id} = _params) do
    asciicast = Asciicasts.get_asciicast!(id)
    do_show(conn, get_format(conn), asciicast)
  end

  def do_show(conn, format, asciicast) when format in ["json", "cast"] do
    path = Asciicast.json_store_path(asciicast)
    filename = download_filename(asciicast, conn.params)
    file_store().serve_file(conn, path, filename)
  end

  @js_max_age 60

  def do_show(conn, "js", _asciicast) do
    path = Application.app_dir(:asciinema, "priv/static/js/embed.js")

    conn
    |> put_resp_content_type("application/javascript")
    |> put_resp_header("cache-control", "public, max-age=#{@js_max_age}")
    |> send_file(200, path)
  end

  @png_max_age 604_800 # 7 days

  def do_show(conn, "png", asciicast) do
    user = Repo.preload(asciicast, :user).user
    png_params = Asciicast.png_params(asciicast, user)

    case PngGenerator.generate(asciicast, png_params) do
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

  def do_show(conn, "gif", asciicast) do
    conn
    |> put_layout("simple.html")
    |> render("gif.html", file_url: asciicast_file_url(conn, asciicast))
  end

  def iframe(conn, %{"id" => id}) do
    asciicast = Asciicasts.get_asciicast!(id)

    conn
    |> put_layout("iframe.html")
    |> delete_resp_header("x-frame-options")
    |> render("iframe.html", file_url: asciicast_file_url(conn, asciicast))
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
end
