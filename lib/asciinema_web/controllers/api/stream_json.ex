defmodule AsciinemaWeb.Api.StreamJSON do
  use AsciinemaWeb, :json
  alias AsciinemaWeb.UrlHelpers
  alias Ecto.Changeset

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
      description: stream.description
    }
  end

  def deleted(_assigns), do: %{}

  def error(%{reason: %Changeset{} = changeset}) do
    %{errors: translate_errors(changeset)}
  end

  def error(%{reason: reason}) do
    %{reason: reason, error: reason}
  end

  def translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end
end
