defmodule AsciinemaWeb.OembedController do
  use AsciinemaWeb, :controller
  alias Asciinema.Asciicasts

  plug :put_layout, nil

  def show(conn, params) do
    uri = URI.parse(params["url"] || "")

    with path when is_binary(path) <- uri.path,
         [_, id] <- Regex.run(~r|^/a/([^/]+)$|, path) do
      asciicast = Asciicasts.get_asciicast!(id)

      mw = if params["maxwidth"], do: String.to_integer(params["maxwidth"])
      mh = if params["maxheight"], do: String.to_integer(params["maxheight"])

      format =
        case params["format"] || get_format(conn) do
          "xml" -> "xml"
          _ -> "json"
        end

      render(
        conn,
        "show.#{format}",
        asciicast: asciicast,
        max_width: mw,
        max_height: mh
      )
    else
      _ ->
        send_resp(conn, 400, "Bad Request")
    end
  end
end
