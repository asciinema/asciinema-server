defmodule AsciinemaAdmin.CliControllerTest do
  use AsciinemaAdmin.ConnCase, async: true

  alias Asciinema.Accounts

  @uuid "cafebabe-cafe-babe-cafe-babecafebabe"

  describe "POST /admin/users/:user_id/clis" do
    test "creates a CLI for a valid UUID install id", %{conn: conn} do
      user = insert(:user)

      conn =
        post(conn, ~p"/admin/users/#{user.id}/clis", %{"cli" => %{"token" => @uuid}})

      assert redirected_to(conn) == ~p"/admin/users/#{user.id}"
      assert flash(conn, :info) =~ "authorized"
      assert [%{token: @uuid}] = Accounts.list_clis(user)
    end

    test "accepts a full asciinema auth URL and extracts the install id", %{conn: conn} do
      user = insert(:user)
      url = "https://asciinema.org/connect/#{@uuid}"

      conn = post(conn, ~p"/admin/users/#{user.id}/clis", %{"cli" => %{"token" => url}})

      assert redirected_to(conn) == ~p"/admin/users/#{user.id}"
      assert flash(conn, :info) =~ "authorized"
      assert [%{token: @uuid}] = Accounts.list_clis(user)
    end

    test "empty token: flashes error and does not crash", %{conn: conn} do
      user = insert(:user)

      conn = post(conn, ~p"/admin/users/#{user.id}/clis", %{"cli" => %{"token" => ""}})

      assert redirected_to(conn) == ~p"/admin/users/#{user.id}"
      assert flash(conn, :error) =~ "invalid"
      assert Accounts.list_clis(user) == []
    end

    test "whitespace-only token: flashes error and does not crash", %{conn: conn} do
      user = insert(:user)

      conn =
        post(conn, ~p"/admin/users/#{user.id}/clis", %{"cli" => %{"token" => "   "}})

      assert redirected_to(conn) == ~p"/admin/users/#{user.id}"
      assert flash(conn, :error) =~ "invalid"
      assert Accounts.list_clis(user) == []
    end

    test "malformed UUID: flashes error and does not crash", %{conn: conn} do
      user = insert(:user)

      conn =
        post(conn, ~p"/admin/users/#{user.id}/clis", %{"cli" => %{"token" => "not-a-uuid"}})

      assert redirected_to(conn) == ~p"/admin/users/#{user.id}"
      assert flash(conn, :error) =~ "invalid"
      assert Accounts.list_clis(user) == []
    end

    test "token already belongs to another registered user: flashes 'already assigned'",
         %{conn: conn} do
      owner = insert(:user)
      _existing_cli = insert(:cli, user: owner, token: @uuid)
      other_user = insert(:user)

      conn =
        post(conn, ~p"/admin/users/#{other_user.id}/clis", %{
          "cli" => %{"token" => @uuid}
        })

      assert redirected_to(conn) == ~p"/admin/users/#{other_user.id}"
      assert flash(conn, :error) =~ "already assigned"
      # Other user got no CLI; original assignment preserved.
      assert Accounts.list_clis(other_user) == []
      assert [%{token: @uuid}] = Accounts.list_clis(owner)
    end
  end
end
