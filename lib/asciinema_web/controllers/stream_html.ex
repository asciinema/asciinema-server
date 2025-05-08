defmodule AsciinemaWeb.StreamHTML do
  use AsciinemaWeb, :html
  import Scrivener.HTML
  alias Asciinema.{Accounts, Fonts, Media, Streaming, Themes}
  alias AsciinemaWeb.{MediaView, RecordingHTML, RecordingSVG}

  embed_templates "stream_html/*"

  defdelegate author_username(stream), to: MediaView
  defdelegate author_avatar_url(stream), to: MediaView
  defdelegate author_profile_path(stream), to: MediaView
  defdelegate theme(stream), to: Media
  defdelegate theme_options, to: MediaView
  defdelegate font_family_options, to: MediaView
  defdelegate short_public_token(stream), to: Streaming

  def player_src(stream) do
    %{
      driver: "websocket",
      url: ws_public_url(stream),
      bufferTime: stream.buffer_time && stream.buffer_time * 1000.0
    }
  end

  def player_opts(stream, opts) do
    [
      cols: term_cols(stream),
      rows: term_rows(stream),
      autoplay: true,
      theme: term_theme_name(stream),
      terminalLineHeight: stream.term_line_height,
      customTerminalFontFamily: Media.font_family(stream)
    ]
    |> Keyword.merge(opts)
    |> Enum.into(%{})
  end

  defp term_theme_name(stream) do
    if stream.term_theme_prefer_original do
      "auto/#{Media.term_theme_name(stream)}"
    else
      Media.term_theme_name(stream)
    end
  end

  def cinema_height(stream) do
    MediaView.cinema_height(term_cols(stream), term_rows(stream))
  end

  def title(stream), do: stream.title || "#{author_username(stream)}'s stream"

  def default_theme_display_name(stream) do
    "Account default (#{Themes.display_name(Accounts.default_term_theme_name(stream.user) || "asciinema")})"
  end

  def default_font_display_name(user) do
    Fonts.display_name(Accounts.default_font_family(user) || "default")
  end

  defp term_cols(stream), do: stream.term_cols || 80

  defp term_rows(stream), do: stream.term_rows || 24

  defp owned_by_current_user?(stream, conn) do
    conn.assigns[:current_user] && conn.assigns[:current_user].id == stream.user_id
  end

  def head("show.html", assigns), do: head_for_show(assigns)
  def head(_, _), do: nil
end
