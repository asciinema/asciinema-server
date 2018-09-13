defmodule AsciinemaWeb.AsciicastView do
  use AsciinemaWeb, :view
  import Scrivener.HTML
  alias Asciinema.Asciicasts
  alias Asciinema.FileStore
  alias AsciinemaWeb.Router.Helpers.Extra, as: Routes
  alias AsciinemaWeb.UserView

  def player(asciicast, opts \\ []) do
    opts =
      Keyword.merge([
        src: file_url(asciicast),
        cols: asciicast.terminal_columns,
        rows: asciicast.terminal_lines,
        poster: base64_poster(asciicast),
        preload: "true",
      ], opts)

    content_tag :"asciinema-player", opts, do: []
  end

  defp file_url(asciicast) do
    path = Asciicasts.asciicast_file_path(asciicast)
    FileStore.url(path) || Routes.asciicast_file_url(asciicast)
  end

  defp base64_poster(asciicast) do
    encoded =
      asciicast
      |> Map.get(:snapshot)
      |> Jason.encode!(escape: :unicode_safe)
      |> Base.encode64()

    "data:application/json;base64," <> encoded
  end

  def active_link(title, active?, opts) do
    opts = if active? do
      class = Keyword.get(opts, :class, "") <> " active"
      Keyword.put(opts, :class, class)
    else
      opts
    end

    link(title, opts)
  end

  def nav_link(title, path, active?) do
    content_tag :li, class: "nav-item" do
      active_link(title, active?, to: path, class: "nav-link")
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
    lines = asciicast.snapshot || []

    lines
    |> drop_trailing_blank_lines
    |> fill_to_height(height)
    |> take_last(height)
    |> adjust_colors
    |> split_chunks
    |> crop_to_width(width)
    |> group_chunks
  end

  def drop_trailing_blank_lines(lines) do
    lines
    |> Enum.reverse
    |> Enum.drop_while(&blank_line?/1)
    |> Enum.reverse
  end

  def fill_to_height(lines, height) do
    if height - Enum.count(lines) > 0 do
      enums = [lines, Stream.cycle([[]])]
      enums
      |> Stream.concat
      |> Enum.take(height)
    else
      lines
    end
  end

  def take_last(lines, height) do
    lines
    |> Enum.reverse
    |> Enum.take(height)
    |> Enum.reverse
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

  def crop_to_width(lines, width) do
    Enum.map(lines, &crop_line_to_width(&1, width))
  end

  def crop_line_to_width(chunks, width) do
    Enum.take(chunks, width)
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
