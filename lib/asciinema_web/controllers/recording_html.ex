defmodule AsciinemaWeb.RecordingHTML do
  use AsciinemaWeb, :html
  import Scrivener.HTML
  alias Asciinema.{Accounts, Fonts, Media, Recordings, Themes}
  alias Asciinema.Recordings.{Markers, Snapshot}
  alias AsciinemaWeb.{MediaView, MediumHTML, UserHTML}

  embed_templates "recording_html/*"

  defdelegate author_username(asciicast), to: MediaView
  defdelegate author_avatar_url(asciicast), to: MediaView
  defdelegate author_profile_path(asciicast), to: MediaView
  defdelegate theme(asciicast), to: Media
  defdelegate term_theme_name(asciicast), to: Media
  defdelegate theme_options(asciicast), to: MediaView
  defdelegate font_family_options, to: MediaView
  defdelegate username(user), to: UserHTML
  defdelegate title(asciicast), to: Recordings
  defdelegate env_info(asciicast), to: MediumHTML

  def player_src(asciicast), do: ~p"/a/#{asciicast}" <> ".#{filename_ext(asciicast)}"

  def player_opts(asciicast, opts) do
    [
      cols: term_cols(asciicast),
      rows: term_rows(asciicast),
      theme: Media.term_theme_name(asciicast),
      terminalLineHeight: asciicast.term_line_height,
      customTerminalFontFamily: Media.font_family(asciicast),
      poster: poster(asciicast.snapshot),
      markers: markers(asciicast.markers),
      idleTimeLimit: asciicast.idle_time_limit,
      speed: asciicast.speed
    ]
    |> Keyword.merge(opts)
    |> Ext.Keyword.rename(t: :startAt)
    |> Enum.into(%{})
  end

  def cinema_height(asciicast) do
    MediaView.cinema_height(term_cols(asciicast), term_rows(asciicast))
  end

  def embed_script(asciicast) do
    src = url(~p"/a/#{asciicast}") <> ".js"
    id = "asciicast-#{Phoenix.Param.to_param(asciicast)}"

    {:safe, "<script src=\"#{src}\" id=\"#{id}\" async=\"true\"></script>"}
  end

  defp asciicast_oembed_url(asciicast, format) do
    url(~p"/oembed?#{%{url: url(~p"/a/#{asciicast}"), format: format}}")
  end

  def original_theme(asciicast) do
    case Media.original_theme(asciicast) do
      nil ->
        []

      theme ->
        [%{fg: theme.fg, bg: theme.bg, palette: Enum.with_index(Tuple.to_list(theme.palette))}]
    end
  end

  def duration(asciicast), do: MediumHTML.format_duration(asciicast.duration)

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

  def term_cols(asciicast), do: asciicast.term_cols_override || asciicast.term_cols

  def term_rows(asciicast), do: asciicast.term_rows_override || asciicast.term_rows

  def default_theme_display_name(asciicast) do
    "Account default (#{Themes.display_name(Accounts.default_term_theme_name(asciicast.user) || "asciinema")})"
  end

  def default_font_display_name(user) do
    Fonts.display_name(Accounts.default_font_family(user) || "default")
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

  defp env_info_attrs(asciicast),
    do: Map.take(asciicast, [:user_agent, :term_type, :term_version, :shell, :uname])

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
      3 -> "application/x-asciicast"
      _ -> nil
    end
  end

  attr :title, :string, required: true
  attr :href, :string, required: true
  attr :active?, :boolean
  attr :rest, :global

  def nav_link(assigns) do
    ~H"""
    <li class="nav-item">
      <.active_link title={@title} href={@href} active?={@active?} class="nav-link" {@rest} />
    </li>
    """
  end

  attr :title, :string, required: true
  attr :href, :string, required: true
  attr :active?, :boolean
  attr :class, :string
  attr :rest, :global

  def active_link(assigns) do
    assigns =
      if assigns[:active?] do
        class = Map.get(assigns, :class, "") <> " active"
        assign(assigns, :class, class)
      else
        assigns
      end

    ~H"""
    <.link href={@href} class={@class} {@rest}>{@title}</.link>
    """
  end

  def download_filename(asciicast) do
    "#{asciicast.id}.#{filename_ext(asciicast)}"
  end

  def filename_ext(%{version: 1}), do: "json"
  def filename_ext(%{version: 2}), do: "cast"
  def filename_ext(%{version: 3}), do: "cast"

  def views_count(asciicast) do
    asciicast.views_count
  end

  def svg_cache_key(asciicast),
    do: Timex.to_unix(asciicast.updated_at) - Timex.to_unix(asciicast.inserted_at)

  defp owned_by_current_user?(asciicast, conn) do
    conn.assigns[:current_user] && conn.assigns[:current_user].id == asciicast.user_id
  end

  def head("show.html", assigns), do: head_for_show(assigns)
  def head(_, _), do: nil
end
