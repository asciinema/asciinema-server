defmodule AsciinemaAdmin.RecordingHTML do
  use AsciinemaAdmin, :html

  embed_templates "recording_html/*"

  def filename_ext(%{version: 1}), do: "json"
  def filename_ext(_), do: "cast"

  @doc "Absolute URL of the asciicast file, served by the public endpoint."
  def player_src(asciicast) do
    AsciinemaWeb.Endpoint.url() <>
      "/a/#{asciicast.secret_token}.#{filename_ext(asciicast)}"
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
