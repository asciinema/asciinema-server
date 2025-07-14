defmodule AsciinemaWeb.Api.StreamJSON do
  use AsciinemaWeb, :json
  alias AsciinemaWeb.UrlHelpers
  alias Ecto.Changeset

  def index(%{streams: streams}) do
    for stream <- streams do
      show(%{stream: stream})
    end
  end

  def show(%{stream: stream}) do
    url = url(~p"/s/#{stream}")
    ws_producer_url = UrlHelpers.ws_producer_url(stream)

    %{
      id: stream.id,
      url: url,
      ws_producer_url: ws_producer_url,
      audio_url: stream.audio_url,
      live: stream.live,
      title: stream.title,
      description: stream.description,
      visibility: stream.visibility
    }
  end

  def deleted(_assigns), do: %{}

  def error(%{legacy_path: _} = assigns) do
    %{reason: error(Map.drop(assigns, [:legacy_path])).message}
  end

  def error(%{reason: reason} = assigns) do
    case reason do
      :unauthenticated ->
        %{type: "unauthenticated", message: "Unauthenticated"}

      :not_found ->
        %{type: "not_found", message: "Stream not found"}

      :access_denied ->
        %{type: "access_denied", message: "You don't have access to this stream"}

      %Changeset{} = changeset ->
        details = translate_errors(changeset)
        %{type: "validation_failed", message: "Validation failed", details: details}

      {:live_stream_limit_reached, limit} ->
        %{type: "live_stream_limit_reached", message: "Maximum #{limit} live streams reached"}
    end
    |> Map.merge(Map.take(assigns, [:message]))
  end

  def translate_errors(changeset) do
    for {field, errors} <- changeset.errors do
      %{field: field, message: translate_error(errors)}
    end
  end
end
