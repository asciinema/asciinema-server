defmodule AsciinemaWeb.OembedJSON do
  use AsciinemaWeb, :json
  import Phoenix.Component, only: [sigil_H: 2]
  alias AsciinemaWeb.{StreamHTML, UserHTML}

  def show(%{asciicast: asciicast, max_width: mw, max_height: mh}) do
    attrs(asciicast, mw, mh)
  end

  def show(%{stream: stream, max_width: mw, max_height: mh}) do
    {width, height} = size_smaller_than(640, 400, mw || 640, mh || 400)
    title = StreamHTML.title(stream)

    %{
      type: "rich",
      version: 1.0,
      title: title,
      author_name: UserHTML.username(stream.user),
      author_url: url(~p"/~#{stream.user}"),
      provider_name: "asciinema",
      provider_url: url(~p"/"),
      html: stream_html(stream, title, width, height),
      width: width,
      height: height
    }
  end

  @cell_width 7.22
  @cell_height 16
  @border_width 12
  # pixel density
  @scale 2

  defp attrs(asciicast, max_width, max_height) do
    cols = asciicast.term_cols_override || asciicast.term_cols
    rows = asciicast.term_rows_override || asciicast.term_rows

    image_width =
      (@scale * (@cell_width * cols + @border_width))
      |> Float.floor()
      |> round()

    image_height =
      (@scale * (@cell_height * rows + @border_width))
      |> round()

    {width, height} =
      size_smaller_than(
        image_width,
        image_height,
        max_width || image_width,
        max_height || image_height
      )

    recording_url = url(~p"/a/#{asciicast}")
    thumbnail_url = recording_url <> ".png"

    %{
      type: "rich",
      version: 1.0,
      title: asciicast.title,
      author_name: UserHTML.username(asciicast.user),
      author_url: url(~p"/~#{asciicast.user}"),
      provider_name: "asciinema",
      provider_url: url(~p"/"),
      thumbnail_url: thumbnail_url,
      thumbnail_width: width,
      thumbnail_height: height,
      html: html(recording_url, thumbnail_url, asciicast.title, width),
      width: width,
      height: height
    }
  end

  defp html(recording_url, thumbnail_url, title, width) do
    assigns = %{url: recording_url, src: thumbnail_url, title: title, width: width}

    ~H|<a href={@url} target="_blank"><img src={@src} alt={@title} width={@width} /></a>|
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp stream_html(stream, title, width, height) do
    assigns = %{src: url(~p"/s/#{stream}/iframe"), title: title, width: width, height: height}

    ~H"""
    <iframe
      src={@src}
      title={@title}
      width={@width}
      height={@height}
      style="border: 0"
      allow="autoplay; fullscreen"
      allowfullscreen
    ></iframe>
    """
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp size_smaller_than(width, height, max_width, max_height) do
    fw = min(max_width, width) / width
    fh = min(max_height, height) / height

    f = min(fw, fh)
    {max(1, round(width * f)), max(1, round(height * f))}
  end
end
