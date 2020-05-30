defmodule AsciinemaWeb do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use AsciinemaWeb, :controller
      use AsciinemaWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: AsciinemaWeb

      alias Asciinema.Repo
      import Ecto
      import Ecto.Query

      import AsciinemaWeb.Router.Helpers
      import AsciinemaWeb.Router.Helpers.Extra
      import AsciinemaWeb.Gettext
      import AsciinemaWeb.Auth, only: [require_current_user: 2]
      import AsciinemaWeb.Plug.ReturnTo
      import AsciinemaWeb.Plug.Authz

      action_fallback AsciinemaWeb.FallbackController

      defp clear_main_class(conn, _) do
        assign(conn, :main_class, "")
      end
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/asciinema_web/templates",
                        namespace: AsciinemaWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import AsciinemaWeb.Router.Helpers
      import AsciinemaWeb.Router.Helpers.Extra
      import AsciinemaWeb.ErrorHelpers
      import AsciinemaWeb.Gettext
      import AsciinemaWeb.ApplicationView
    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      alias Asciinema.Repo
      import Ecto
      import Ecto.Query
      import AsciinemaWeb.Gettext
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
