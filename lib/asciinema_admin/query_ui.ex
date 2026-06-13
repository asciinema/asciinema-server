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
      <p class="muted">Press <kbd>/</kbd> anywhere to focus the search box.</p>
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

  defp help_content(:users) do
    assigns = %{}

    ~H"""
    <div class="query-help-grid">
      <section>
        <h3>Basics</h3>
        <pre>alice
    id:123
    email:gmail.com
    admin:yes
    created:30d
    login:&gt;=2026-01-01
    recordings:&gt;10
    streams:0..2</pre>
      </section>
      <section>
        <h3>Filters</h3>
        <pre>id:&lt;int&gt;
    username:&lt;text&gt;
    email:&lt;text&gt;
    name:&lt;text&gt;
    admin:&lt;yes|no&gt;
    created:&lt;date&gt;
    login:&lt;date&gt;
    recordings:&lt;number&gt;
    streams:&lt;number&gt;</pre>
      </section>
    </div>
    <p class="muted">
      Spaces separate terms. Quoted values are not supported. Numbers can be exact (e.g. 0), a
      comparison (&gt;10), or a <code>..</code> range. Invalid filters block the search.
    </p>
    """
  end

  defp help_content(:recordings) do
    assigns = %{}

    ~H"""
    <div class="query-help-grid">
      <section>
        <h3>Basics</h3>
        <pre>deploy visibility:public
    featured:yes views:&gt;1000
    archived:no size:&gt;100mb
    stream:true
    stream:123
    duration:10m..1h</pre>
      </section>
      <section>
        <h3>Filters</h3>
        <pre>id:&lt;int&gt;
    title:&lt;text&gt;
    user:&lt;username|id&gt;
    visibility:&lt;public|unlisted|private&gt;
    featured:&lt;yes|no&gt;
    archived:&lt;yes|no&gt;
    created:&lt;date&gt;
    duration:&lt;duration&gt;
    size:&lt;size&gt;
    views:&lt;number&gt;
    stream:&lt;yes|no|id&gt;
    audio:&lt;yes|no&gt;
    token:&lt;secret token&gt;</pre>
      </section>
    </div>
    <p class="muted">
      Dates: today, 2026-01-01, 30m, 30h, 30d. Numbers, durations and sizes can be exact (e.g.
      views:0), a comparison (&gt;, &gt;=, &lt;, &lt;=), or a <code>..</code> range.
    </p>
    """
  end

  defp help_content(:streams) do
    assigns = %{}

    ~H"""
    <div class="query-help-grid">
      <section>
        <h3>Basics</h3>
        <pre>deploy visibility:public
    live:yes
    scheduled:yes
    started:never
    peak-viewers:&gt;50
    recordings:&gt;0
    created:30d</pre>
      </section>
      <section>
        <h3>Filters</h3>
        <pre>id:&lt;int&gt;
    title:&lt;text&gt;
    user:&lt;username|id&gt;
    visibility:&lt;public|unlisted|private&gt;
    live:&lt;yes|no&gt;
    scheduled:&lt;yes|no&gt;
    audio:&lt;yes|no&gt;
    created:&lt;date&gt;
    started:&lt;date|never&gt;
    current-viewers:&lt;number&gt;
    peak-viewers:&lt;number&gt;
    recordings:&lt;number&gt;
    token:&lt;public token&gt;</pre>
      </section>
    </div>
    <p class="muted">
      Spaces separate terms. Quoted values are not supported. Numbers can be exact (e.g. 0), a
      comparison (&gt;10), or a <code>..</code> range. Invalid filters block the search.
    </p>
    """
  end

  defp suggestions(:users) do
    %{
      tokens: ~w[id username email name admin created login recordings streams],
      values: %{
        admin: ~w[yes no],
        created: ["30d", "today", ">=2026-01-01"],
        login: ["30d", "today", ">=2026-01-01"],
        recordings: ["0", ">10", "0..2"],
        streams: ["0", ">10", "0..2"]
      }
    }
  end

  defp suggestions(:recordings) do
    %{
      tokens:
        ~w[id title user visibility featured archived created duration size views stream audio token],
      values: %{
        visibility: ~w[public unlisted private],
        featured: ~w[yes no],
        archived: ~w[yes no],
        created: ["30d", "today", ">=2026-01-01"],
        duration: ["10m", ">10m", "10m..1h"],
        size: ["100mb", ">100mb", "100mb..1gb"],
        views: ["0", ">1000", "100..1000"],
        stream: ["yes", "no"],
        audio: ~w[yes no]
      }
    }
  end

  defp suggestions(:streams) do
    %{
      tokens:
        ~w[id title user visibility live scheduled audio created started current-viewers peak-viewers recordings token],
      values: %{
        visibility: ~w[public unlisted private],
        live: ~w[yes no],
        scheduled: ~w[yes no],
        audio: ~w[yes no],
        created: ["30d", "today", ">=2026-01-01"],
        started: ["never", "30d", ">=2026-01-01"],
        "current-viewers": ["0", ">10", "0..2"],
        "peak-viewers": ["0", ">50", "10..100"],
        recordings: ["0", ">0", "0..2"]
      }
    }
  end
end
