defmodule AsciinemaWeb.RecordingView do
  alias AsciinemaWeb.PlayerView
  use AsciinemaWeb, :view
  import Scrivener.HTML
  alias Asciinema.Recordings.Asciicast
  alias AsciinemaWeb.Endpoint
  alias AsciinemaWeb.Router.Helpers.Extra, as: RoutesX
  alias AsciinemaWeb.{PlayerView, UserView}
  import UserView, only: [theme_options: 0]

  defdelegate author_username(asciicast), to: PlayerView
  defdelegate author_avatar_url(stream), to: PlayerView
  defdelegate author_profile_path(stream), to: PlayerView
  defdelegate theme_name(stream), to: PlayerView
  defdelegate default_theme_name(stream), to: PlayerView
  defdelegate terminal_font_family_options, to: PlayerView
  defdelegate username(user), to: UserView

  def player_src(asciicast), do: file_url(asciicast)

  def player_opts(asciicast, opts) do
    [
      cols: cols(asciicast),
      rows: rows(asciicast),
      theme: theme_name(asciicast),
      terminalLineHeight: asciicast.terminal_line_height,
      customTerminalFontFamily: asciicast.terminal_font_family,
      poster: poster(asciicast.snapshot),
      markers: markers(asciicast.markers),
      idleTimeLimit: asciicast.idle_time_limit
    ]
    |> Keyword.merge(opts)
    |> Ext.Keyword.rename(t: :startAt)
    |> Enum.into(%{})
  end

  def cinema_height(asciicast) do
    PlayerView.cinema_height(cols(asciicast), rows(asciicast))
  end

  def embed_script(asciicast) do
    src = Routes.recording_url(Endpoint, :show, asciicast) <> ".js"
    id = "asciicast-#{Phoenix.Param.to_param(asciicast)}"
    content_tag(:script, [src: src, id: id, async: true], do: [])
  end

  defp file_url(asciicast) do
    RoutesX.asciicast_file_url(asciicast)
  end

  defp asciicast_oembed_url(asciicast, format) do
    Routes.oembed_url(
      Endpoint,
      :show,
      url: Routes.recording_url(Endpoint, :show, asciicast),
      format: format
    )
  end

  defp short_text_description(asciicast) do
    if asciicast.description do
      asciicast.description
      |> HtmlSanitizeEx.strip_tags()
      |> String.replace(~r/[\r\n]+/, " ")
      |> truncate(200)
    else
      "Recorded by #{author_username(asciicast)}"
    end
  end

  defp truncate(text, length) do
    if String.length(text) > length do
      String.slice(text, 0, length - 3) <> "..."
    else
      text
    end
  end

  defp alternate_link_type(asciicast) do
    case asciicast.version do
      1 -> "application/asciicast+json"
      2 -> "application/x-asciicast"
      _ -> nil
    end
  end

  def download_filename(asciicast) do
    case asciicast.version do
      1 -> "#{asciicast.id}.json"
      2 -> "#{asciicast.id}.cast"
      _ -> nil
    end
  end

  @csi_init "\x1b["
  @sgr_reset "\x1b[0m"

  defp poster(nil), do: nil

  defp poster(snapshot) do
    text =
      snapshot
      |> Enum.map(&line_to_text/1)
      |> Enum.join("\r\n")
      |> String.replace(~r/(\r\n\s+)+$/, "")

    "data:text/plain," <> text <> @csi_init <> "?25l"
  end

  defp markers(nil), do: nil

  defp markers(markers) do
    case Asciicast.parse_markers(markers) do
      {:ok, markers} -> Enum.map(markers, &Tuple.to_list/1)
      {:error, _} -> nil
    end
  end

  defp line_to_text(segments) do
    segments
    |> Enum.map(&segment_to_text/1)
    |> Enum.join("")
    |> String.replace(~r/\e\[0m\s*$/, "\e[0m")
  end

  defp segment_to_text([text, attrs]) do
    params =
      attrs
      |> Enum.reject(fn {_k, v} -> v == false end)
      |> sgr_params()

    case params do
      [] ->
        text

      params ->
        @csi_init <> Enum.join(params, ";") <> "m" <> text <> @sgr_reset
    end
  end

  defp sgr_params([{k, v} | rest]) do
    param =
      case {k, v} do
        {"fg", c} when is_number(c) and c < 8 -> "3#{c}"
        {"fg", c} when is_number(c) -> "38;5;#{c}"
        {"fg", "rgb(" <> _} -> "38;2;#{parse_rgb(v)}"
        {"fg", [r, g, b]} -> "38;2;#{r};#{g};#{b}"
        {"bg", c} when is_number(c) and c < 8 -> "4#{c}"
        {"bg", c} when is_number(c) -> "48;5;#{c}"
        {"bg", "rgb(" <> _} -> "48;2;#{parse_rgb(v)}"
        {"bg", [r, g, b]} -> "48;2;#{r};#{g};#{b}"
        {"bold", true} -> "1"
        {"faint", true} -> "2"
        {"italic", true} -> "3"
        {"underline", true} -> "4"
        {"blink", true} -> "5"
        {"inverse", true} -> "7"
        {"strikethrough", true} -> "9"
      end

    [param | sgr_params(rest)]
  end

  defp sgr_params([]), do: []

  defp parse_rgb("rgb(" <> c) do
    c
    |> String.slice(0, String.length(c) - 1)
    |> String.split(",")
    |> Enum.join(";")
  end

  def os_info(asciicast) do
    os_from_user_agent(asciicast) || os_from_uname(asciicast)
  end

  defp os_from_user_agent(asciicast) do
    if ua = asciicast.user_agent do
      if match = Regex.run(~r{^asciinema/\d(\.\d+)+ [^/\s]+/[^/\s]+ (.+)$}, ua) do
        [_, _, os] = match

        os
        |> String.replace("-", "/")
        |> String.split("/")
        |> List.first()
        |> String.replace(~r/Darwin/i, "macOS")
      end
    end
  end

  defp os_from_uname(asciicast) do
    if uname = asciicast.uname do
      cond do
        uname =~ ~r/Linux/i -> "Linux"
        uname =~ ~r/Darwin/i -> "macOS"
        true -> uname |> String.split(~r/[\s-]/) |> List.first()
      end
    end
  end

  def shell_info(asciicast) do
    Path.basename("#{asciicast.shell}")
  end

  def term_info(asciicast) do
    asciicast.terminal_type
  end

  def views_count(asciicast) do
    asciicast.views_count
  end

  def active_link(title, active?, opts) do
    opts =
      if active? do
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

      true ->
        "untitled"
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

  def class(%{} = attrs) do
    attrs
    |> Enum.map(&class/1)
    |> Enum.join(" ")
  end

  def class({"fg", fg}) when is_integer(fg), do: "fg-#{fg}"
  def class({"bg", bg}) when is_integer(bg), do: "bg-#{bg}"
  def class({"bold", true}), do: "bright"
  def class({"faint", true}), do: "faint"
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

  defp add_style(styles, attr, "rgb(" <> _ = rgb) do
    ["#{attr}:#{rgb}" | styles]
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
    |> Enum.reverse()
    |> Enum.drop_while(&blank_line?/1)
    |> Enum.reverse()
  end

  def fill_to_height(lines, height) do
    if height - Enum.count(lines) > 0 do
      enums = [lines, Stream.cycle([[]])]

      enums
      |> Stream.concat()
      |> Enum.take(height)
    else
      lines
    end
  end

  def take_last(lines, height) do
    lines
    |> Enum.reverse()
    |> Enum.take(height)
    |> Enum.reverse()
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
    {text, adjust_attrs_colors(attrs)}
  end

  def adjust_attrs_colors(attrs) do
    attrs
    |> adjust_fg()
    |> adjust_bg()
    |> invert_colors()
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
    split_chunk({text, attrs})
  end

  def split_chunk({text, attrs}) do
    text
    |> String.codepoints()
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
    {chunks, last_chunk} =
      Enum.reduce(chunks, {[], first_chunk}, fn {text, attrs},
                                                {chunks, {prev_text, prev_attrs}} ->
        if attrs == prev_attrs do
          {chunks, {prev_text <> text, attrs}}
        else
          {[{prev_text, prev_attrs} | chunks], {text, attrs}}
        end
      end)

    Enum.reverse([last_chunk | chunks])
  end

  def render("show.svg", %{asciicast: asciicast} = params) do
    lines = adjust_colors(asciicast.snapshot || [])

    bg_lines = add_coords(lines)

    text_lines =
      lines
      |> split_chunks()
      |> add_coords()
      |> remove_blank_chunks()

    render(
      "_terminal.svg",
      cols: cols(asciicast),
      rows: rows(asciicast),
      bg_lines: bg_lines,
      text_lines: text_lines,
      rx: params[:rx],
      ry: params[:ry],
      font_family: params[:font_family],
      theme_name: theme_name(asciicast)
    )
  end

  defp add_coords(lines) do
    for {chunks, y} <- Enum.with_index(lines) do
      {_, chunks} =
        Enum.reduce(chunks, {0, []}, fn {text, attrs}, {x, chunks} ->
          width = String.length(text)
          chunk = %{text: text, attrs: attrs, x: x, width: width}
          {x + width, [chunk | chunks]}
        end)

      chunks = Enum.reverse(chunks)

      %{y: y, chunks: chunks}
    end
  end

  defp remove_blank_chunks(lines) do
    for line <- lines do
      chunks = Enum.reject(line.chunks, &(String.trim(&1.text) == ""))
      %{line | chunks: chunks}
    end
  end

  def svg_text_class(%{} = attrs) do
    classes =
      attrs
      |> Enum.reject(fn {attr, _} -> attr == "bg" end)
      |> Enum.map(&svg_text_class/1)
      |> Enum.filter(& &1)

    case classes do
      [] -> nil
      _ -> Enum.join(classes, " ")
    end
  end

  def svg_text_class({"fg", fg}) when is_integer(fg), do: "c-#{fg}"
  def svg_text_class({"bold", true}), do: "br"
  def svg_text_class({"faint", true}), do: "fa"
  def svg_text_class({"italic", true}), do: "it"
  def svg_text_class({"underline", true}), do: "un"
  def svg_text_class(_), do: nil

  def svg_rect_style(%{"bg" => [_r, _g, _b] = c}), do: "fill:#{hex(c)}"
  def svg_rect_style(%{"bg" => "rgb(" <> _ = c}), do: "fill:#{c}"
  def svg_rect_style(_), do: nil

  def svg_rect_class(%{"bg" => bg}) when is_integer(bg), do: "c-#{bg}"
  def svg_rect_class(_), do: nil

  def svg_text_style(%{"fg" => [_r, _g, _b] = c}), do: "fill:#{hex(c)}"
  def svg_text_style(%{"fg" => "rgb(" <> _ = c}), do: "fill:#{c}"
  def svg_text_style(_), do: nil

  defp hex([r, g, b]) do
    "##{hex(r)}#{hex(g)}#{hex(b)}"
  end

  defp hex(int) do
    int
    |> Integer.to_string(16)
    |> String.pad_leading(2, "0")
  end

  def percent(float) do
    "#{Decimal.round(Decimal.from_float(float), 3)}%"
  end

  def recording_gc_days, do: Asciinema.recording_gc_days()

  defp cols(asciicast), do: asciicast.cols_override || asciicast.cols

  defp rows(asciicast), do: asciicast.rows_override || asciicast.rows
end
