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
  slot :actions
  slot :inner_block, required: true

  def page(assigns) do
    ~H"""
    <div class={["page", @class]}>
      <header class="page-header">
        <div class="page-title">
          <img :if={@avatar} src={@avatar} class="avatar" alt="" />
          <h1>{@title}</h1>
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

  @doc "A small label tag for visibility/state badges."
  attr :variant, :atom, default: :default, values: [:default, :muted, :danger, :success]
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

  @doc """
  Avatar + username link to the admin user page. No whitespace between the
  avatar and the name — the gap is pure CSS margin.
  """
  attr :user, :any, required: true

  def user_link(%{user: nil} = assigns) do
    ~H"""
    <span class="muted">—</span>
    """
  end

  def user_link(assigns) do
    ~H"""
    <.link href={~p"/admin/users/#{@user.id}"} class="user-cell">
      <img src={avatar_url(@user)} class="avatar avatar-sm" alt="" />{@user.username || @user.id}
    </.link>
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
  def format_bytes(nil), do: "—"
  def format_bytes(b) when b < 1024, do: "#{b} B"
  def format_bytes(b) when b < 1024 * 1024, do: "#{Float.round(b / 1024, 1)} KB"
  def format_bytes(b), do: "#{Float.round(b / (1024 * 1024), 1)} MB"

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

  @doc """
  Renders a compressed/uncompressed/ratio summary like
  `2.3 MB (8.1 MB) [28%]`, with each number wrapped in `<abbr>` so the
  browser shows a tooltip explaining what it is. Renders `"—"` when
  either input is missing or the uncompressed size is zero.
  """
  attr :compressed, :integer, default: nil
  attr :uncompressed, :integer, default: nil

  def bytes_summary(assigns) do
    ~H"""
    <%= if @compressed && @uncompressed && @uncompressed > 0 do %>
      <abbr title="compressed size (bytes stored on disk)">{format_bytes(@compressed)}</abbr>
      (<abbr title="uncompressed size (original bytes)">{format_bytes(@uncompressed)}</abbr>)
      [<abbr title="compression ratio: compressed ÷ uncompressed">{round(@compressed / @uncompressed * 100)}%</abbr>]
    <% else %>
      —
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
end
