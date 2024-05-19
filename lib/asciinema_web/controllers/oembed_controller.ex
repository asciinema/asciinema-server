defmodule AsciinemaWeb.OembedController do
  use AsciinemaWeb, :controller
  alias Asciinema.Recordings

  plug :put_layout, nil

  def show(conn, params) do
    with {:ok, path} <- parse_url(params["url"] || ""),
         {:ok, id} <- extract_id(path),
         {:ok, asciicast} <- Recordings.fetch_asciicast(id),
         :ok <- authorize(asciicast) do
      {mw, mh} = get_size(params)
      format = get_embed_format(conn)

      render(
        conn,
        "show.#{format}",
        asciicast: asciicast,
        max_width: mw,
        max_height: mh
      )
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_url(url) do
    case URI.parse(url).path do
      nil -> {:error, :bad_request}
      path -> {:ok, path}
    end
  end

  defp extract_id(path) do
    case Regex.run(~r|^/a/([^/]+)$|, path) do
      [_, id] -> {:ok, id}
      _ -> {:error, :bad_request}
    end
  end

  defp authorize(asciicast) do
    if asciicast.visibility == :private do
      {:error, :forbidden}
    else
      :ok
    end
  end

  defp get_size(params) do
    mw = if params["maxwidth"], do: String.to_integer(params["maxwidth"])
    mh = if params["maxheight"], do: String.to_integer(params["maxheight"])

    {mw, mh}
  end

  defp get_embed_format(conn) do
    case conn.params["format"] || get_format(conn) do
      "xml" -> "xml"
      _ -> "json"
    end
  end
end
