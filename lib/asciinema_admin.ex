defmodule AsciinemaAdmin do
  @moduledoc """
  Entry point for the admin Phoenix application.

  Use as:

      use AsciinemaAdmin, :controller
      use AsciinemaAdmin, :router

  Definitions below run for every controller/router/etc; keep them small.
  Helper functions belong in their own modules.
  """

  def static_paths, do: ~w(css fonts images js favicon.ico robots.txt)

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html]
      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def html do
    quote do
      use Phoenix.Component

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
