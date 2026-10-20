defmodule AsciinemaWeb.OembedController do
  use AsciinemaWeb, :controller
  alias Asciinema.{Recordings, Streaming}
  alias AsciinemaWeb.Authorization

  plug :put_layout, html: false

  def show(conn, params) do
    with {:ok, path} <- parse_url(params["url"] || ""),
         {:ok, assigns} <- load_and_authorize(path) do
      {mw, mh} = get_size(params)
      format = get_embed_format(conn)

      render(
        conn,
        "show.#{format}",
        Keyword.merge(assigns, max_width: mw, max_height: mh)
      )
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp load_and_authorize_asciicast(id) do
    case Recordings.lookup_asciicast(id) do
      nil ->
        {:error, :not_found}

      asciicast ->
        if Authorization.can?(nil, :show, asciicast) do
          {:ok, asciicast: asciicast}
        else
          if Recordings.secret_token?(id), do: {:error, :forbidden}, else: {:error, :not_found}
        end
    end
  end

  defp load_and_authorize_stream(token) do
    case Streaming.find_stream_by_public_token(token) do
      %{user: %{streaming_enabled: true}} = stream ->
        if Authorization.can?(nil, :show, stream) do
          {:ok, stream: stream}
        else
          {:error, :forbidden}
        end

      _ ->
        {:error, :not_found}
    end
  end

  defp parse_url(url) do
    case URI.parse(url).path do
      nil -> {:error, :bad_request}
      path -> {:ok, path}
    end
  end

  defp load_and_authorize(path) do
    case Regex.run(~r"^/(a|s)/([^/]+)$", path) do
      [_, "a", id] -> load_and_authorize_asciicast(id)
      [_, "s", token] -> load_and_authorize_stream(token)
      _ -> {:error, :bad_request}
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
