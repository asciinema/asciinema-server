defmodule AsciinemaAdmin.CoreComponents do
  @moduledoc """
  Admin-only UI components. Independent from `AsciinemaWeb.CoreComponents`.
  """
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: AsciinemaAdmin.Endpoint,
    router: AsciinemaAdmin.Router,
    statics: AsciinemaAdmin.static_paths()

  @doc "A page wrapper."
  attr :title, :string, required: true
  attr :avatar, :string, default: nil
  attr :class, :string, default: nil
  slot :status, doc: "state badges beside the title"
  slot :actions
  slot :inner_block, required: true

  def page(assigns) do
    ~H"""
    <div class={["page", @class]}>
      <header class="page-header">
        <div class="page-title">
          <img :if={@avatar} src={@avatar} class="avatar" alt="" />
          <h1>{@title}</h1>
          {render_slot(@status)}
        </div>
        <div :if={@actions != []} class="page-actions">
          {render_slot(@actions)}
        </div>
      </header>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "A button."
  attr :type, :string, default: "button"
  attr :variant, :atom, default: :default, values: [:default, :primary, :danger]
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href name value disabled form)
  slot :inner_block, required: true

  def button(assigns) do
    tag = if Map.get(assigns.rest, :href), do: :a, else: :button
    assigns = assign(assigns, :tag, tag)

    ~H"""
    <.dynamic_tag
      tag_name={"#{@tag}"}
      class={["btn", "btn-#{@variant}", @class]}
      type={if @tag == :button, do: @type}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  @doc "Header dropdown for page actions; closes on outside click or Escape (admin.js)."
  slot :inner_block, required: true

  def action_menu(assigns) do
    ~H"""
    <details class="action-menu">
      <summary class="btn">Actions ▾</summary>
      <div class="action-menu-panel">
        {render_slot(@inner_block)}
      </div>
    </details>
    """
  end

  @doc "A small label tag for visibility/state badges."
  attr :variant, :atom, default: :default, values: [:default, :muted, :danger, :success, :live]
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def tag(assigns) do
    ~H"""
    <span class={["tag", "tag-#{@variant}", @class]}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr :page, Scrivener.Page, required: true
  attr :params, :map, default: %{}

  def pagination(%{page: %{total_pages: total_pages}} = assigns) when total_pages <= 1 do
    ~H""
  end

  def pagination(assigns) do
    page = assigns.page

    assigns =
      assign(assigns,
        items: pagination_items(page.page_number, page.total_pages),
        params: assigns.params
      )

    ~H"""
    <nav class="pagination">
      <.page_item :for={item <- @items} item={item} params={@params} />
    </nav>
    """
  end

  defp pagination_items(current, total) do
    prev = if current > 1, do: [{:prev, current - 1}], else: []
    next = if current < total, do: [{:next, current + 1}], else: []

    prev ++ [{:page, current, total}] ++ next
  end

  defp page_item(%{item: {:prev, page}} = assigns) do
    assigns = assign(assigns, :page, page)

    ~H"""
    <.link href={page_href(@page, @params)} rel="prev" class="pg-prev">← Previous</.link>
    """
  end

  defp page_item(%{item: {:next, page}} = assigns) do
    assigns = assign(assigns, :page, page)

    ~H"""
    <.link href={page_href(@page, @params)} rel="next" class="pg-next">Next →</.link>
    """
  end

  defp page_item(%{item: {:page, page, total}} = assigns) do
    assigns = assign(assigns, page: page, total: total)

    ~H"""
    <span class="active pg-page">Page {@page} of {@total}</span>
    """
  end

  defp page_href(1, params), do: "?" <> URI.encode_query(params)

  defp page_href(page, params), do: "?" <> URI.encode_query(Map.put(params, :page, page))

  @doc "Maps a recording/stream visibility to a `tag/1` variant."
  def visibility_variant(:public), do: :success
  def visibility_variant(:unlisted), do: :default
  def visibility_variant(:private), do: :muted
  def visibility_variant(_), do: :default

  @doc "Placeholder for an absent value: a muted em dash."
  def none(assigns) do
    ~H"""
    <span class="none">—</span>
    """
  end

  @doc "Muted middle-dot separator; spacing comes from CSS margins, not template whitespace."
  def sep(assigns) do
    ~H|<span class="sep">·</span>|
  end

  @doc "Eight ANSI palette colors of a named terminal theme, for palette_strip/1."
  def named_theme_colors(name) do
    name
    |> Asciinema.Themes.named_theme()
    |> Asciinema.Themes.preview_colors()
  end

  @doc "Label for a medium's configured theme selection."
  def theme_setting_label(medium) do
    case theme_setting(medium) do
      :original ->
        "original"

      {:named, name, inherited} ->
        Asciinema.Themes.display_name(name) <> if(inherited, do: " (default)", else: "")
    end
  end

  @doc "Palette colors for the configured theme, or nil when set to original."
  def theme_setting_colors(medium) do
    case theme_setting(medium) do
      :original -> nil
      {:named, name, _inherited} -> named_theme_colors(name)
    end
  end

  defp theme_setting(medium) do
    cond do
      medium.term_theme_name == "original" -> :original
      medium.term_theme_name -> {:named, medium.term_theme_name, false}
      true -> {:named, Asciinema.Accounts.default_term_theme_name(medium.user), true}
    end
  end

  @doc "Eight colors of the medium's captured original palette, or nil when never captured."
  def original_theme_colors(medium) do
    if theme = Asciinema.Media.original_theme(medium) do
      Asciinema.Themes.preview_colors(theme)
    end
  end

  @doc "The medium's captured env vars sorted by name; names are validated upper-case."
  def env_vars(medium), do: Enum.sort(medium.env || %{})

  @doc """
  Avatar + username link to the admin user page. No whitespace between the
  avatar and the name — the gap is pure CSS margin.
  """
  attr :user, :any, required: true

  def user_link(%{user: nil} = assigns) do
    ~H"""
    <.none />
    """
  end

  def user_link(assigns) do
    ~H"""
    <.link href={~p"/admin/users/#{@user.id}"} class="user-cell">
      <img src={avatar_url(@user)} class="avatar avatar-sm" alt="" />{@user.username ||
        @user.temporary_username || @user.id}
    </.link>
    """
  end

  @doc "Renders user Markdown to sanitized HTML with the public site's renderer."
  defdelegate render_markdown(input), to: AsciinemaWeb.ApplicationView

  @doc "Absolute URL of a recording, stream, or user profile on the public site."
  def public_url(%Asciinema.Recordings.Asciicast{} = asciicast),
    do: AsciinemaWeb.Endpoint.url() <> "/a/" <> Phoenix.Param.to_param(asciicast)

  def public_url(%Asciinema.Streaming.Stream{} = stream),
    do: AsciinemaWeb.Endpoint.url() <> "/s/" <> Phoenix.Param.to_param(stream)

  def public_url(%Asciinema.Accounts.User{} = user),
    do: AsciinemaWeb.Endpoint.url() <> "/~" <> Phoenix.Param.to_param(user)

  @doc "Links a recording, stream, or user to its public page, with the URL as the link text."
  attr :entity, :any, required: true

  def public_link(assigns) do
    assigns = assign(assigns, :url, public_url(assigns.entity))

    ~H"""
    <.link href={@url} target="_blank" rel="noopener">{@url}</.link>
    """
  end

  @doc "Absolute avatar URL for admin pages."
  def avatar_url(user) do
    url = AsciinemaWeb.DefaultAvatar.url(user)

    if String.starts_with?(url, "/") and not String.starts_with?(url, "//") do
      AsciinemaWeb.Endpoint.url() <> url
    else
      url
    end
  end

  @doc "Inline SVG sparkline from integers or `{key, integer}` pairs; stroked with currentColor."
  attr :values, :list, required: true
  attr :width, :integer, default: 320
  attr :height, :integer, default: 48
  attr :class, :string, default: nil

  def sparkline(assigns) do
    counts =
      Enum.map(assigns.values, fn
        {_k, c} -> c
        c when is_integer(c) -> c
      end)

    n = length(counts)
    peak = counts |> Enum.max(fn -> 0 end) |> max(1)

    points =
      if n > 1 do
        # pad top/bottom so the stroke doesn't clip
        pad = 1.5
        usable_h = assigns.height - pad * 2

        counts
        |> Enum.with_index()
        |> Enum.map_join(" ", fn {c, i} ->
          x = i / (n - 1) * assigns.width
          y = pad + (1 - c / peak) * usable_h
          "#{Float.round(x, 1)},#{Float.round(y, 1)}"
        end)
      end

    assigns = assign(assigns, points: points, peak: peak, total: Enum.sum(counts))

    ~H"""
    <svg
      class={["sparkline", @class]}
      viewBox={"0 0 #{@width} #{@height}"}
      width={@width}
      height={@height}
      preserveAspectRatio="none"
      role="img"
      aria-label={"sparkline, peak #{@peak}, total #{@total}"}
    >
      <polyline
        :if={@points}
        points={@points}
        fill="none"
        stroke="currentColor"
        stroke-width="1.5"
        stroke-linejoin="round"
        stroke-linecap="round"
      />
    </svg>
    """
  end

  @doc "Format byte count as B / KB / MB."
  def format_bytes(nil), do: nil
  def format_bytes(b) when b < 1024, do: "#{b} B"
  def format_bytes(b) when b < 1024 * 1024, do: "#{Float.round(b / 1024, 1)} KB"
  def format_bytes(b), do: "#{Float.round(b / (1024 * 1024), 1)} MB"

  @doc "Format duration as `HH:MM:SS` or `MM:SS`."
  def format_duration(nil), do: nil

  def format_duration(seconds) when is_float(seconds) do
    total = round(seconds)
    h = div(total, 3600)
    m = div(rem(total, 3600), 60)
    s = rem(total, 60)

    if h > 0,
      do: :io_lib.format("~B:~2..0B:~2..0B", [h, m, s]) |> IO.iodata_to_binary(),
      else: :io_lib.format("~B:~2..0B", [m, s]) |> IO.iodata_to_binary()
  end

  @doc "Size summary like `2.3 MB (8.1 MB) [28%]`, with explanatory `<abbr>` tooltips."
  attr :compressed, :integer, default: nil
  attr :uncompressed, :integer, default: nil

  def bytes_summary(assigns) do
    ~H"""
    <%= if @compressed && @uncompressed && @uncompressed > 0 do %>
      <abbr title="compressed size (bytes stored on disk)">{format_bytes(@compressed)}</abbr>
      (<abbr title="uncompressed size (original bytes)">{format_bytes(@uncompressed)}</abbr>)
      [<abbr title="compression ratio: compressed ÷ uncompressed">{round(@compressed / @uncompressed * 100)}%</abbr>]
    <% else %>
      <.none />
    <% end %>
    """
  end

  @doc "First error message for a form field (interpolated), or nil."
  def error_message(%Phoenix.HTML.FormField{errors: []}), do: nil

  def error_message(%Phoenix.HTML.FormField{errors: [{msg, opts} | _]}) do
    Enum.reduce(opts, msg, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end)
  end

  @doc ~S(An absolute time as "X ago", with the full timestamp in the title attribute.)
  attr :time, :any, required: true
  attr :rest, :global

  def time_ago(assigns) do
    ~H"""
    <time
      datetime={Timex.format!(@time, "{ISO:Extended:Z}")}
      title={Timex.format!(@time, "{RFC1123z}")}
      {@rest}
    >
      {Timex.from_now(@time)}
    </time>
    """
  end

  # Terminal kv value renderers, shared by the recording and stream show pages.

  @doc "Terminal size value (cols × rows)."
  attr :cols, :any, default: nil
  attr :rows, :any, default: nil

  def term_size(assigns) do
    ~H"""
    {@cols || "?"} × {@rows || "?"}
    """
  end

  @doc "Terminal type and version value."
  attr :type, :any, default: nil
  attr :version, :any, default: nil

  def term_type(assigns) do
    ~H"""
    <code :if={@type}>{@type}<span :if={@version} class="muted"><.sep />{@version}</span></code>
    <.none :if={!@type} />
    """
  end

  @doc "An 8-colour palette as SVG bars; crispEdges keeps them gapless at any zoom."
  attr :colors, :list, required: true

  def palette_strip(assigns) do
    ~H"""
    <svg
      class="palette-strip"
      viewBox="0 0 8 1"
      width="112"
      height="14"
      preserveAspectRatio="none"
      shape-rendering="crispEdges"
      role="img"
      aria-label="terminal palette"
    >
      <rect :for={{c, i} <- Enum.with_index(@colors)} x={i} y="0" width="1" height="1" fill={c} />
    </svg>
    """
  end

  @doc """
  Sets the player's `--term-color-*` variables — "original" theme colors
  exist only as DB columns, so the page must supply them.
  """
  attr :medium, :any, required: true

  def term_theme_style(assigns) do
    assigns = assign(assigns, :theme, Asciinema.Media.theme(assigns.medium))

    ~H"""
    <style>
      .admin-player div.ap-player {
        --term-color-foreground: <%= @theme.fg %>;
        --term-color-background: <%= @theme.bg %>;
        <%= for {c, i} <- Enum.with_index(Tuple.to_list(@theme.palette)) do %>
        --term-color-<%= i %>: <%= c %>;
        <% end %>
      }
    </style>
    """
  end

  @doc "Theme `{label, value}` options for a medium's theme select."
  def theme_options(medium) do
    for theme <- original_theme_option(medium) ++ Asciinema.Themes.terminal_themes() do
      {Asciinema.Themes.display_name(theme), theme}
    end
  end

  defp original_theme_option(%{term_theme_palette: nil}), do: []
  defp original_theme_option(_medium), do: ["original"]

  @doc "Label for the blank theme option: the user's account default theme."
  def default_theme_label(medium) do
    name = Asciinema.Accounts.default_term_theme_name(medium.user)

    "Account default (#{Asciinema.Themes.display_name(name)})"
  end

  @doc "Font family `{label, value}` options for a medium's font select."
  def font_family_options do
    for family <- Asciinema.Fonts.terminal_font_families() do
      {Asciinema.Fonts.display_name(family), family}
    end
  end

  @doc "Label for the blank font option: the user's account default font."
  def default_font_label(medium) do
    family = Asciinema.Accounts.default_font_family(medium.user) || "default"

    "Account default (#{Asciinema.Fonts.display_name(family)})"
  end

  @doc "Terminal font value (family, with line height when set)."
  attr :family, :any, default: nil
  attr :line_height, :any, default: nil

  def term_font(assigns) do
    ~H"""
    {@family}<.none :if={!@family} />
    <span :if={@line_height} class="muted">
      <.sep />{@line_height} lh
    </span>
    """
  end
end
