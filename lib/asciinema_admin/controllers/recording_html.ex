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

  @doc "Format duration as `HH:MM:SS` or `MM:SS`."
  def format_duration(nil), do: "—"

  def format_duration(seconds) when is_float(seconds) do
    total = round(seconds)
    h = div(total, 3600)
    m = div(rem(total, 3600), 60)
    s = rem(total, 60)

    if h > 0,
      do: :io_lib.format("~B:~2..0B:~2..0B", [h, m, s]) |> IO.iodata_to_binary(),
      else: :io_lib.format("~B:~2..0B", [m, s]) |> IO.iodata_to_binary()
  end
end
