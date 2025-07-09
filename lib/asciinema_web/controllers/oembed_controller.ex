defmodule AsciinemaWeb.OembedController do
  use AsciinemaWeb, :controller
  alias Asciinema.{Recordings, Authorization}

  plug :put_layout, nil

  def show(conn, params) do
    with {:ok, path} <- parse_url(params["url"] || ""),
         {:ok, id} <- extract_id(path),
         {:ok, asciicast} <- load_and_authorize_asciicast(id) do
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

  defp load_and_authorize_asciicast(id) do
    {asciicast, ctx, status} =
      cond do
        String.match?(id, ~r/^\d+$/) ->
          {Recordings.get_asciicast(id), %{}, :not_found}

        String.match?(id, ~r/^[[:alnum:]]{25}$/) ->
          {Recordings.find_asciicast_by_secret_token(id), %{id: id}, :forbidden}

        true ->
          {nil, %{}}
      end

    if asciicast do
      resource = Map.merge(asciicast, ctx)

      if Authorization.can?(nil, :show, resource) do
        {:ok, asciicast}
      else
        {:error, status}
      end
    else
      {:error, :not_found}
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
