defmodule AsciinemaWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint AsciinemaWeb.Endpoint

      use AsciinemaWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest

      import Asciinema.Fixtures
      alias AsciinemaWeb.Router.Helpers, as: Routes

      defp flash(conn, key) do
        Phoenix.Flash.get(conn.assigns.flash, key)
      end

      def log_in(conn, user) do
        conn
        |> assign(:current_user, user)
        |> assign(:default_stream, nil)
      end
    end
  end

  setup tags do
    Asciinema.DataCase.setup_sandbox(tags)

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
