defmodule AsciinemaWeb.UrlHelpers do
  use Phoenix.VerifiedRoutes,
    endpoint: AsciinemaWeb.Endpoint,
    router: AsciinemaWeb.Router

  alias AsciinemaWeb.Endpoint

  def profile_path(_conn, user), do: profile_path(user)

  def profile_path(%Plug.Conn{} = conn), do: profile_path(conn.assigns.current_user)

  def profile_path(%{id: id, username: username}) do
    if username do
      ~p"/~#{username}"
    else
      ~p"/u/#{id}"
    end
  end

  def profile_url(user) do
    Endpoint.url() <> profile_path(user)
  end

  def asciicast_file_path(asciicast) do
    ~p"/a/#{asciicast}" <> "." <> ext(asciicast)
  end

  def asciicast_file_url(asciicast) do
    url(~p"/a/#{asciicast}") <> "." <> ext(asciicast)
  end

  defp ext(asciicast) do
    case asciicast.version do
      1 -> "json"
      2 -> "cast"
    end
  end

  @http_to_ws %{"http" => "ws", "https" => "wss"}

  def ws_producer_url(stream) do
    uri = Endpoint.struct_url()
    scheme = @http_to_ws[uri.scheme]
    path = "/ws/S/#{stream.producer_token}"

    to_string(%{uri | scheme: scheme, path: path})
  end

  def ws_public_url(stream) do
    uri = Endpoint.struct_url()
    scheme = @http_to_ws[uri.scheme]
    param = Phoenix.Param.to_param(stream)
    path = "/ws/s/#{param}"

    to_string(%{uri | scheme: scheme, path: path})
  end
end
