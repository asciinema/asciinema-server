defmodule AsciinemaAdmin.CoreComponents do
  @moduledoc """
  Admin-only UI components. Independent from `AsciinemaWeb.CoreComponents`.
  """
  use Phoenix.Component

  @doc "A page wrapper."
  attr :title, :string, required: true
  attr :class, :string, default: nil
  slot :actions
  slot :inner_block, required: true

  def page(assigns) do
    ~H"""
    <div class={["page", @class]}>
      <header class="page-header">
        <h1>{@title}</h1>
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
end
