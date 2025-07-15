defmodule AsciinemaWeb.FeatureCase do
  @moduledoc """
  This module defines the test case to be used by
  feature tests using Phoenix.Test.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint AsciinemaWeb.Endpoint

      use AsciinemaWeb, :verified_routes

      import PhoenixTest

      import Phoenix.ConnTest,
        only: [
          init_test_session: 2,
          post: 2,
          redirected_to: 1
        ]

      import Asciinema.Fixtures
      import Asciinema.Factory

      def log_in_user(conn, user) do
        init_test_session(conn, %{user_id: user.id})
      end

      defp link_from_email do
        assert_received {:email, %Swoosh.Email{} = email}
        [_, link] = Regex.run(~r{"(https?://[^"]+)"}, email.html_body)

        link
      end

      defp verify_magic_link(session) do
        # Simulate the automatic JS submit by submitting a hidden form
        [_, url] = Regex.run(~r{action="(/[^"]+)".+method="post"}, session.conn.resp_body)

        conn = post(session.conn, url)
        visit(conn, redirected_to(conn))
      end
    end
  end

  setup tags do
    Asciinema.DataCase.setup_sandbox(tags)

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
