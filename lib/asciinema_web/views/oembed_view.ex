defmodule AsciinemaWeb.OembedView do
  use AsciinemaWeb, :view
  alias AsciinemaWeb.Endpoint
  alias AsciinemaWeb.UserView

  def render("show.json", %{asciicast: asciicast, max_width: mw, max_height: mh}) do
    attrs(asciicast, mw, mh)
  end

  def render("show.xml", %{asciicast: asciicast, max_width: mw, max_height: mh}) do
    render("_show.xml", attrs(asciicast, mw, mh))
  end

  @cell_width 7.22
  @cell_height 16
  @border_width 12
  # pixel density
  @scale 2

  defp attrs(asciicast, max_width, max_height) do
    image_width =
      (@scale * (@cell_width * asciicast.terminal_columns + @border_width))
      |> Float.floor()
      |> round()

    image_height =
      (@scale * (@cell_height * asciicast.terminal_lines + @border_width))
      |> round()

    {width, height} =
      size_smaller_than(
        image_width,
        image_height,
        max_width || image_width,
        max_height || image_height
      )

    asciicast_url = Routes.asciicast_url(Endpoint, :show, asciicast)
    thumbnail_url = asciicast_url <> ".png"

    %{
      type: "rich",
      version: 1.0,
      title: asciicast.title,
      author_name: UserView.username(asciicast.user),
      author_url: profile_url(asciicast.user),
      provider_name: "asciinema",
      provider_url: root_url(),
      thumbnail_url: thumbnail_url,
      thumbnail_width: width,
      thumbnail_height: height,
      html: html(asciicast_url, thumbnail_url, asciicast.title, width),
      width: width,
      height: height
    }
  end

  defp html(asciicast_url, thumbnail_url, title, width) do
    safe =
      content_tag(:a, href: asciicast_url, target: "_blank") do
        img_tag(thumbnail_url, alt: title, width: width)
      end

    Phoenix.HTML.safe_to_string(safe)
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
