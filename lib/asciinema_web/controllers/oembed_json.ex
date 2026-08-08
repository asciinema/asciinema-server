defmodule AsciinemaWeb.OembedJSON do
  use AsciinemaWeb, :json
  import Phoenix.Component, only: [sigil_H: 2]
  alias AsciinemaWeb.UserHTML

  def show(%{asciicast: asciicast, max_width: mw, max_height: mh}) do
    attrs(asciicast, mw, mh)
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

  defp size_smaller_than(width, height, max_width, max_height) do
    fw = max_width / width
    fh = max_height / height

    if fw > 1 && fh > 1 do
      {width, height}
    else
      f = min(fw, fh)
      {round(width * f), round(height * f)}
    end
  end
end
