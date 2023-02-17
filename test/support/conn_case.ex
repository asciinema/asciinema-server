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
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest

      import AsciinemaWeb.Router.Helpers.Extra
      import Asciinema.Fixtures
      alias AsciinemaWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint AsciinemaWeb.Endpoint

      def log_in(conn, user) do
        assign(conn, :current_user, user)
      end
    end
  end

  setup tags do
    Asciinema.DataCase.setup_sandbox(tags)

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
