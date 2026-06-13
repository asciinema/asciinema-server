defmodule AsciinemaAdmin.QueryUI do
  @moduledoc "Components and helpers for admin index querying."
  use Phoenix.Component

  alias AsciinemaAdmin.QuerySort

  attr :index, :map, required: true
  attr :action, :string, required: true
  attr :placeholder, :string, required: true
  attr :return_to, :string, required: true

  def query_form(assigns) do
    assigns =
      assign(assigns,
        suggestions: suggestions(assigns.index.entity) |> Jason.encode!(),
        help_id: "#{assigns.index.entity}-query-help"
      )

    ~H"""
    <div class="filter-bar query-filter">
      <form method="get" action={@action} class="query-get-form">
        <div class="query-input-wrap" data-query-autocomplete data-suggestions={@suggestions}>
          <input
            type="search"
            name="q"
            value={@index.q}
            placeholder={@placeholder}
            title="Press / to focus"
            autocomplete="off"
            spellcheck="false"
          />
          <a
            :if={@index.q != ""}
            href={@action}
            class="query-clear-btn"
            aria-label="Clear search"
            title="Clear search"
          >
            <AsciinemaAdmin.Icons.x_mark_icon />
          </a>
          <button
            type="button"
            class="query-help-btn"
            data-dialog-target={@help_id}
            aria-label="Query syntax help"
            title="Query syntax help"
          >
            <AsciinemaAdmin.Icons.info_outline_icon />
          </button>
        </div>

        <select name="sort" aria-label="Sort" data-autosubmit>
          <option
            :for={sort <- @index.sort_options}
            value={sort.param}
            selected={sort.param == @index.sort_param}
          >
            {sort.label}
          </option>
        </select>
      </form>

      <div :if={@index.active_saved_query} class="saved-query-match">
        Saved query
        <.form
          for={%{}}
          method="put"
          action={"/admin/saved_queries/#{@index.active_saved_query.id}"}
          data-prompt="Rename saved query"
        >
          <input type="hidden" name="name" value={@index.active_saved_query.name} />
          <input type="hidden" name="return_to" value={@return_to} />
          <button type="submit" class="link-button">Rename</button>
        </.form>
        <.form
          for={%{}}
          method="delete"
          action={"/admin/saved_queries/#{@index.active_saved_query.id}"}
          data-confirm={"Delete saved query \"#{@index.active_saved_query.name}\"?"}
        >
          <input type="hidden" name="return_to" value={@return_to} />
          <button type="submit" class="link-button">Delete</button>
        </.form>
      </div>
      <.form
        :if={@index.q != "" and is_nil(@index.active_saved_query)}
        for={%{}}
        method="post"
        action="/admin/saved_queries"
        data-prompt="Save this search as"
      >
        <input type="hidden" name="entity" value={@index.entity} />
        <input type="hidden" name="filter" value={@index.q} />
        <input type="hidden" name="sort" value={@index.sort_param} />
        <input type="hidden" name="return_to" value={@return_to} />
        <input type="hidden" name="name" value="" />
        <button type="submit" class="btn">Save query</button>
      </.form>
    </div>

    <div :if={@index.errors != []} class="query-errors">
      <strong>Query not run.</strong>
      <ul>
        <li :for={error <- @index.errors}>{error}</li>
      </ul>
    </div>

    <dialog id={@help_id} class="admin-dialog query-help">
      <header class="dialog-header">
        <h2>{help_title(@index.entity)}</h2>
        <form method="dialog" class="dialog-close">
          <button aria-label="Close">×</button>
        </form>
      </header>
      {help_content(@index.entity)}
    </dialog>
    """
  end

  def sort_params(index, target_param) do
    Map.merge(index.query_params, %{sort: QuerySort.sort_link_param(index.sort, target_param)})
  end

  def sort_arrow(index, target_param), do: QuerySort.sort_arrow(index.sort, target_param)

  defp help_title(:users), do: "User query syntax"
  defp help_title(:recordings), do: "Recording query syntax"
  defp help_title(:streams), do: "Stream query syntax"

  defp help_content(entity) do
    assigns = %{
      intro: intro(entity),
      filters: filters(entity),
      value_help: value_help_rows(entity)
    }

    ~H"""
    <p class="query-help-intro">{@intro}</p>

    <table class="query-help-table">
      <thead>
        <tr>
          <th>Filter</th>
          <th>Meaning</th>
          <th>Example</th>
        </tr>
      </thead>
      <tbody>
        <tr :for={f <- @filters}>
          <td class="mono">{"#{f.token}:<#{f.placeholder}>"}</td>
          <td>{f.meaning}</td>
          <td class="mono">{f.example}</td>
        </tr>
      </tbody>
    </table>

    <h3 class="query-help-subhead">Values &amp; operators</h3>

    <table class="query-help-table">
      <tbody>
        <tr :for={{type, forms} <- @value_help}>
          <td class="mono">{type}</td>
          <td>{Phoenix.HTML.raw(forms)}</td>
        </tr>
      </tbody>
    </table>

    <p class="muted">
      Comparison operators (&gt; &gt;= &lt; &lt;=) and ranges (low..high) work with date, number,
      duration and size values.
    </p>
    """
  end

  # Bare words search the identity (users) or title (recordings/streams).
  defp intro(:users) do
    "Bare words search username, email and name. Combine filters with spaces — all terms must match. Quotes aren't supported."
  end

  defp intro(_entity) do
    "Bare words search the title. Combine filters with spaces — all terms must match. Quotes aren't supported."
  end

  @doc """
  Single source of truth for an entity's filter vocabulary. Drives both this
  help table and the autocomplete suggestions; a test asserts the parser's
  accepted token set equals these tokens.
  """
  def filters(:users) do
    [
      f("id", :id, "User ID", "id:123"),
      f("username", :text, "Username contains", "username:alice"),
      f("email", :text, "Email contains", "email:gmail.com"),
      f("name", :text, "Display name contains", "name:alice"),
      f("admin", :boolean, "Has admin access", "admin:yes"),
      f(
        "registered",
        :boolean,
        "Has an account (temporary users do not)",
        "registered:no"
      ),
      f("created", :date, "Signup date", "created:30d"),
      f("login", :date, "Last login", "login:>=2026-01-01"),
      f("recordings", :number, "Recording count", "recordings:>10"),
      f("streams", :number, "Stream count", "streams:0..2")
    ]
  end

  def filters(:recordings) do
    [
      f("id", :id, "Recording ID", "id:123"),
      f("title", :text, "Title contains", "title:deploy"),
      f("user", :user, "Owner", "user:alice", placeholder: "username|id"),
      f("visibility", :enum, "Visibility", "visibility:public",
        placeholder: "public|unlisted|private",
        values: ~w[public unlisted private]
      ),
      f("featured", :boolean, "Featured", "featured:yes"),
      f("archived", :boolean, "Archived", "archived:no"),
      f("created", :date, "Creation date", "created:30d"),
      f("duration", :duration, "Length", "duration:10m..1h"),
      f("size", :size, "Compressed size", "size:>100mb"),
      f("views", :number, "View count", "views:>1000"),
      f("stream", :boolean, "Belongs to a stream", "stream:yes", placeholder: "yes|no|id"),
      f("audio", :boolean, "Has audio", "audio:yes"),
      f("token", :token, "Exact secret token", "token:abc123", placeholder: "token")
    ]
  end

  def filters(:streams) do
    [
      f("id", :id, "Stream ID", "id:123"),
      f("title", :text, "Title contains", "title:deploy"),
      f("user", :user, "Owner", "user:alice", placeholder: "username|id"),
      f("visibility", :enum, "Visibility", "visibility:public",
        placeholder: "public|unlisted|private",
        values: ~w[public unlisted private]
      ),
      f("live", :boolean, "Currently live", "live:yes"),
      f("scheduled", :boolean, "Scheduled", "scheduled:yes"),
      f("audio", :boolean, "Has audio", "audio:yes"),
      f("created", :date, "Creation date", "created:30d"),
      f("started", :date, "Last started", "started:never",
        placeholder: "date|never",
        values: ["never", "30d", ">=2026-01-01"]
      ),
      f("current-viewers", :number, "Current viewers", "current-viewers:>10"),
      f("peak-viewers", :number, "Peak viewers", "peak-viewers:>50"),
      f("recordings", :number, "Recording count", "recordings:>0"),
      f("token", :token, "Exact public token", "token:abc123", placeholder: "token")
    ]
  end

  defp f(token, type, meaning, example, opts \\ []) do
    %{
      token: token,
      type: type,
      meaning: meaning,
      example: example,
      placeholder: opts[:placeholder] || placeholder(type),
      values: opts[:values] || type_values(type)
    }
  end

  defp placeholder(:id), do: "number"
  defp placeholder(:number), do: "number"
  defp placeholder(:text), do: "text"
  defp placeholder(:boolean), do: "yes|no"
  defp placeholder(:date), do: "date"
  defp placeholder(:duration), do: "duration"
  defp placeholder(:size), do: "size"

  defp type_values(:boolean), do: ~w[yes no]
  defp type_values(:date), do: ["today", "30d", ">=2026-01-01"]
  defp type_values(:number), do: ["0", ">10", "0..2"]
  defp type_values(:duration), do: ["10m", ">10m", "10m..1h"]
  defp type_values(:size), do: ["100mb", ">100mb", "100mb..1gb"]
  defp type_values(_type), do: []

  # The shared reference shows only the value types this entity actually uses,
  # in a fixed order. Enums and one-off forms stay inline in the filter cell.
  # The forms column is static, developer-authored HTML rendered verbatim.
  @value_help [
    {:text, {"text", "substring match, e.g. <code>gmail.com</code>"}},
    {:boolean, {"yes | no", "also accepts <code>true</code> / <code>false</code>"}},
    {:date,
     {"date",
      "<code>today</code>, <code>2026-01-01</code>, or a window like <code>30m</code> / <code>30h</code> / <code>30d</code>"}},
    {:number, {"number", "e.g. <code>10</code>, <code>&gt;1000</code>, <code>100..1000</code>"}},
    {:duration, {"duration", "e.g. <code>10s</code>, <code>10m</code>, <code>1h</code>"}},
    {:size, {"size", "e.g. <code>100kb</code>, <code>10mb</code>, <code>1gb</code>"}}
  ]

  defp value_help_rows(entity) do
    types = filters(entity) |> Enum.map(& &1.type) |> MapSet.new()

    for {type, row} <- @value_help, MapSet.member?(types, type), do: row
  end

  defp suggestions(entity) do
    specs = filters(entity)

    %{
      tokens: Enum.map(specs, & &1.token),
      values: for(s <- specs, s.values != [], into: %{}, do: {s.token, s.values})
    }
  end
end
