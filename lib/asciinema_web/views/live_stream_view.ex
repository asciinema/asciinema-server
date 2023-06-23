defmodule AsciinemaWeb.LiveStreamView do
  use AsciinemaWeb, :view
  alias AsciinemaWeb.UserView

  def player_src(stream) do
    %{
      driver: "websocket",
      url: ws_consumer_url(stream),
      bufferTime: 1.0
    }
  end

  def cinema_height(stream) do
    # TODO make it live - with cinema height automatically recalculated and updated

    AsciinemaWeb.RecordingView.cinema_height(%{
      cols: stream.cols || 80,
      rows: stream.rows || 24,
      cols_override: nil,
      rows_override: nil
    })
  end

  def author_username(stream) do
    UserView.username(stream.user)
  end

  def author_avatar_url(stream) do
    UserView.avatar_url(stream.user)
  end

  def author_profile_path(stream) do
    profile_path(stream.user)
  end

  # TODO use Routes
  defp ws_consumer_url(live_stream) do
    String.replace(AsciinemaWeb.Endpoint.url() <> "/ws/s/#{live_stream.id}", ~r/^http/, "ws")
  end
end
