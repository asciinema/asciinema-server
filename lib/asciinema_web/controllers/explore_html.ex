defmodule AsciinemaWeb.ExploreHTML do
  use AsciinemaWeb, :html
  alias AsciinemaWeb.RecordingHTML

  embed_templates "explore_html/*"

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
end
