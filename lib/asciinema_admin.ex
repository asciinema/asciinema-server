defmodule AsciinemaAdmin do
  @moduledoc """
  Entry point for the admin Phoenix application.

  Use as:

      use AsciinemaAdmin, :controller
      use AsciinemaAdmin, :router
      use AsciinemaAdmin, :live_view
      use AsciinemaAdmin, :html

  Definitions below run for every controller/router/etc; keep them small.
  Helper functions belong in their own modules.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html],
        layouts: [html: AsciinemaAdmin.Layouts]

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView, layout: {AsciinemaAdmin.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      unquote(html_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  defp html_helpers do
    quote do
      import Phoenix.HTML
      import AsciinemaAdmin.CoreComponents
      import AsciinemaAdmin.QueryUI

      alias Phoenix.LiveView.JS

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: AsciinemaAdmin.Endpoint,
        router: AsciinemaAdmin.Router,
        statics: AsciinemaAdmin.static_paths()
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
