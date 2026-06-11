defmodule AsciinemaAdmin.RecordingHTML do
  use AsciinemaAdmin, :html

  alias Asciinema.Media
  alias Asciinema.Recordings.{Markers, Snapshot}

  embed_templates "recording_html/*"

  @doc "Cast file URL on the admin endpoint — same-origin, no visibility checks."
  def player_src(asciicast) do
    ~p"/admin/recordings/#{asciicast.id}/file"
  end

  @doc """
  Suggested filename for downloading the cast file: `username-id.ext`. The
  admin file endpoint serves the file decompressed, so no .zst suffix.
  """
  def download_filename(asciicast) do
    ext = if asciicast.version == 1, do: "json", else: "cast"
    "#{asciicast.user.username || asciicast.user_id}-#{asciicast.id}.#{ext}"
  end

  @doc """
  Mirrors `AsciinemaWeb.RecordingHTML.player_opts/2` so the admin preview
  plays back like the public player.
  """
  def player_opts(asciicast) do
    %{
      cols: asciicast.term_cols_override || asciicast.term_cols,
      rows: asciicast.term_rows_override || asciicast.term_rows,
      theme: Media.term_theme_name(asciicast),
      boldIsBright: asciicast.term_bold_is_bright,
      adaptivePalette: asciicast.term_adaptive_palette,
      terminalLineHeight: asciicast.term_line_height,
      customTerminalFontFamily: Media.font_family(asciicast),
      poster: poster(asciicast.snapshot),
      markers: markers(asciicast.markers),
      idleTimeLimit: asciicast.idle_time_limit,
      speed: asciicast.speed,
      audioUrl: asciicast.audio_url
    }
  end

  defp poster(nil), do: nil

  defp poster(snapshot) do
    "data:text/plain," <> Snapshot.seq(snapshot)
  end

  defp markers(nil), do: nil

  defp markers(markers) do
    case Markers.parse(markers) do
      {:ok, markers} -> Enum.map(markers, &Tuple.to_list/1)
      {:error, _} -> nil
    end
  end
end
