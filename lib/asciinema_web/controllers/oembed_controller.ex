defmodule AsciinemaWeb.OembedController do
  use AsciinemaWeb, :new_controller
  alias Asciinema.Recordings

  plug :put_layout, nil

  def show(conn, params) do
    uri = URI.parse(params["url"] || "")

    with path when is_binary(path) <- uri.path,
         [_, id] <- Regex.run(~r|^/a/([^/]+)$|, path),
         {:ok, asciicast} <- Recordings.fetch_asciicast(id) do
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
      {:error, :not_found} ->
        {:error, :not_found}

      _ ->
        {:error, :bad_request}
    end
  end
end
