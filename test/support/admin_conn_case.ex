defmodule AsciinemaAdmin.ConnCase do
  @moduledoc """
  Test case for AsciinemaAdmin (admin endpoint) controller and live tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint AsciinemaAdmin.Endpoint

      use AsciinemaAdmin, :verified_routes

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Plug.Conn
      import Phoenix.ConnTest
      import Asciinema.Factory
      import Asciinema.Fixtures

      defp flash(conn, key) do
        Phoenix.Flash.get(conn.assigns.flash, key)
      end
    end
  end

  setup tags do
    Asciinema.DataCase.setup_sandbox(tags)

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
