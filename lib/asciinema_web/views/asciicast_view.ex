defmodule AsciinemaWeb.AsciicastView do
  use AsciinemaWeb, :view
  import Phoenix.Controller, only: [action_name: 1]
  import Scrivener.HTML
  alias AsciinemaWeb.UserView

  def active_link(title, active?, opts) do
    opts = if active? do
      class = Keyword.get(opts, :class, "") <> " active"
      Keyword.put(opts, :class, class)
    else
      opts
    end

    link(title, opts)
  end

  def nav_link(title, path, conn, id) do
    content_tag :li, class: "nav-item" do
      active_link(title, action_name(conn) == id, to: path, class: "nav-link")
    end
  end

  def title(asciicast) do
    cond do
      present?(asciicast.title) ->
        asciicast.title
      present?(asciicast.command) && asciicast.command != asciicast.shell ->
        asciicast.command
      asciicast.private ->
        "untitled"
      true ->
        "asciicast:#{asciicast.id}"
    end
  end

  def duration(asciicast) do
    if d = asciicast.duration do
      d = round(d)
      minutes = div(d, 60)
      seconds = rem(d, 60)
      :io_lib.format("~2..0B:~2..0B", [minutes, seconds])
    end
  end

  def theme_name(asciicast) do
    asciicast.theme_name || UserView.theme_name(asciicast.user) || "asciinema"
  end

  def author_username(asciicast) do
    UserView.username(asciicast.user)
  end

  def author_avatar_url(asciicast) do
    UserView.avatar_url(asciicast.user)
  end

  def author_profile_path(asciicast) do
    profile_path(asciicast.user)
  end

  def class(%{} = attrs) do
    attrs
    |> Enum.map(&class/1)
    |> Enum.join(" ")
  end

  def class({"fg", fg}) when is_integer(fg), do: "fg-#{fg}"
  def class({"bg", bg}) when is_integer(bg), do: "bg-#{bg}"
  def class({"bold", true}), do: "bright"
  def class({"underline", true}), do: "underline"
  def class(_), do: nil

  def style(attrs) do
    styles =
      []
      |> add_style("color", attrs["fg"])
      |> add_style("background-color", attrs["bg"])

    case styles do
      [] -> nil
      _ -> Enum.join(styles, ";")
    end
  end

  defp add_style(styles, attr, [r, g, b]) do
    ["#{attr}:rgb(#{r},#{g},#{b})" | styles]
  end
  defp add_style(styles, _, _), do: styles

  def thumbnail(asciicast, width \\ 80, height \\ 15) do
    lines = asciicast.snapshot || Enum.take(Stream.cycle([[]]), height)
    y = Enum.count(lines) - height - count_trailing_blank_lines(lines)

    lines
    |> adjust_colors
    |> split_chunks
    |> crop(0, y, width, height)
    |> group_chunks
  end

  def count_trailing_blank_lines(lines) do
    lines
    |> Enum.reverse
    |> Enum.take_while(&blank_line?/1)
    |> Enum.count
  end

  def blank_line?(line) do
    Enum.all?(line, &blank_chunk?/1)
  end

  def blank_chunk?(["", _attrs]), do: true
  def blank_chunk?([text, attrs]) do
    text = String.trim(text)
    text == "" && attrs == %{}
  end

  def adjust_colors(lines) do
    Enum.map(lines, &adjust_line_colors/1)
  end

  def adjust_line_colors(chunks) do
    Enum.map(chunks, &adjust_chunk_colors/1)
  end

  def adjust_chunk_colors([text, attrs]) do
    [text, adjust_attrs_colors(attrs)]
  end

  def adjust_attrs_colors(attrs) do
    attrs
    |> adjust_fg
    |> adjust_bg
    |> invert_colors
  end

  def adjust_fg(%{"bold" => true, "fg" => fg} = attrs)
  when is_integer(fg) and fg < 8 do
    Map.put(attrs, "fg", fg + 8)
  end
  def adjust_fg(attrs), do: attrs

  def adjust_bg(%{"blink" => true, "bg" => bg} = attrs)
  when is_integer(bg) and bg < 8 do
    Map.put(attrs, "bg", bg + 8)
  end
  def adjust_bg(attrs), do: attrs

  @default_fg_code 7
  @default_bg_code 0

  def invert_colors(%{"inverse" => true} = attrs) do
    fg = attrs["bg"] || @default_bg_code
    bg = attrs["fg"] || @default_fg_code
    Map.merge(attrs, %{"fg" => fg, "bg" => bg})
  end
  def invert_colors(attrs), do: attrs

  def split_chunks(lines) do
    Enum.map(lines, fn line ->
      Enum.flat_map(line, &split_chunk/1)
    end)
  end

  def split_chunk([text, attrs]) do
    text
    |> String.codepoints
    |> Enum.map(&{&1, attrs})
  end

  def crop(lines, x, y, width, height) do
    lines
    |> Enum.drop(y)
    |> Enum.take(height)
    |> Enum.map(&crop_line(&1, x, width))
  end

  def crop_line(chunks, x, width) do
    chunks
    |> Enum.drop(x)
    |> Enum.take(width)
  end

  def group_chunks(lines) do
    Enum.map(lines, &group_line_chunks/1)
  end

  def group_line_chunks([]), do: []

  def group_line_chunks([first_chunk | chunks]) do
    {chunks, last_chunk} = Enum.reduce(chunks, {[], first_chunk},
      fn {text, attrs}, {chunks, {prev_text, prev_attrs}}  ->
        if attrs == prev_attrs do
          {chunks, {prev_text <> text, attrs}}
        else
          {[{prev_text, prev_attrs} | chunks], {text, attrs}}
        end
      end
    )

    Enum.reverse([last_chunk | chunks])
  end
end
