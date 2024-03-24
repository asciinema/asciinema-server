defmodule AsciinemaWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use AsciinemaWeb, :controller
      use AsciinemaWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths, do: ~w(css fonts images js favicon.ico robots.txt)

  def controller do
    quote do
      use Phoenix.Controller, namespace: AsciinemaWeb

      import Plug.Conn
      import AsciinemaWeb.Gettext
      import AsciinemaWeb.Router.Helpers.Extra
      import AsciinemaWeb.Auth, only: [require_current_user: 2]
      import AsciinemaWeb.Plug.ReturnTo
      import AsciinemaWeb.Plug.Authz
      alias AsciinemaWeb.Router.Helpers, as: Routes

      unquote(verified_routes())

      action_fallback AsciinemaWeb.FallbackController

      defp clear_main_class(conn, _) do
        assign(conn, :main_class, "")
      end
    end
  end

  def new_controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json, :svg]

      import Plug.Conn
      import AsciinemaWeb.Gettext
      import AsciinemaWeb.Router.Helpers.Extra
      import AsciinemaWeb.Auth, only: [require_current_user: 2]
      import AsciinemaWeb.Plug.ReturnTo
      import AsciinemaWeb.Plug.Authz

      unquote(verified_routes())

      action_fallback AsciinemaWeb.FallbackController

      defp clear_main_class(conn, _) do
        assign(conn, :main_class, "")
      end
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/asciinema_web/templates",
        namespace: AsciinemaWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(view_helpers())
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

  def channel do
    quote do
      use Phoenix.Channel

      import AsciinemaWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      use Phoenix.Component
      import Phoenix.View

      # Core UI components and translation
      import AsciinemaWeb.CoreComponents
      import AsciinemaWeb.Gettext
      import AsciinemaWeb.Icons

      import AsciinemaWeb.ErrorHelpers
      alias AsciinemaWeb.Router.Helpers, as: Routes

      import AsciinemaWeb.Router.Helpers.Extra
      import AsciinemaWeb.ApplicationView

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def html do
    quote do
      use Phoenix.Component
      import Phoenix.View
      import AsciinemaWeb.ApplicationView

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML

      # Core UI components and translation
      import AsciinemaWeb.CoreComponents
      import AsciinemaWeb.Gettext
      import AsciinemaWeb.Icons

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def json do
    quote do
      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: AsciinemaWeb.Endpoint,
        router: AsciinemaWeb.Router,
        statics: AsciinemaWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  alias AsciinemaWeb.Router.Helpers, as: Routes
  alias AsciinemaWeb.Endpoint

  def instance_hostname do
    Endpoint.url()
    |> URI.parse()
    |> Map.get(:host)
  end

  def signup_url(token) do
    Routes.users_url(Endpoint, :new, t: token)
  end

  def login_url(token) do
    Routes.session_url(Endpoint, :new, t: token)
  end
end
