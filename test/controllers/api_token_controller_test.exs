defmodule Asciinema.ApiTokenControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory

  describe "register" do
    test "as a guest redirects to login page", %{conn: conn} do
      conn = get(conn, ~p"/connect/00000000-0000-0000-0000-000000000000")

      assert redirected_to(conn, 302) == ~p"/login/new"
      assert flash(conn, :info)
    end

    test "with invalid token shows error", %{conn: conn} do
      user = insert(:user)
      conn = log_in(conn, user)

      conn = get(conn, ~p"/connect/nopenope")

      assert redirected_to(conn, 302) == "/"
      assert flash(conn, :error) =~ ~r/invalid/i
    end

    test "with revoked token shows error", %{conn: conn} do
      user = insert(:user)
      api_token = insert(:revoked_api_token, user: user)
      conn = log_in(conn, user)

      conn = get(conn, ~p"/connect/#{api_token.token}")

      assert redirected_to(conn, 302) == "/"
      assert flash(conn, :error) =~ ~r/been revoked/i
    end

    test "with tmp user token shows notice, redirects to profile page", %{conn: conn} do
      user = insert(:user, username: "test")
      tmp_user = insert(:temporary_user)
      api_token = insert(:api_token, user: tmp_user)
      conn = log_in(conn, user)

      conn = get(conn, ~p"/connect/#{api_token.token}")

      assert redirected_to(conn, 302) == ~p"/~test"
      assert flash(conn, :info) =~ ~r/successfully/
    end

    test "with their own token shows notice, redirects to profile page", %{conn: conn} do
      user = insert(:user, username: "test")
      api_token = insert(:api_token, user: user)
      conn = log_in(conn, user)

      conn = get(conn, ~p"/connect/#{api_token.token}")

      assert redirected_to(conn, 302) == ~p"/~test"
      assert flash(conn, :info) =~ ~r/successfully/
    end

    test "with other user's token shows error, redirects to profile page", %{conn: conn} do
      user = insert(:user, username: "test")
      api_token = insert(:api_token)
      conn = log_in(conn, user)

      conn = get(conn, ~p"/connect/#{api_token.token}")

      assert redirected_to(conn, 302) == ~p"/~test"
      assert flash(conn, :error) =~ ~r/different/
    end
  end

  describe "delete" do
    test "as a guest redirects to login page", %{conn: conn} do
      conn = delete(conn, ~p"/api_tokens/123")

      assert redirected_to(conn, 302) == ~p"/login/new"
      assert flash(conn, :info)
    end

    test "with user's own token shows notice, redirects to settings", %{conn: conn} do
      user = insert(:user)
      api_token = insert(:api_token, user: user)
      conn = log_in(conn, user)

      conn = delete(conn, ~p"/api_tokens/#{api_token.id}")

      assert redirected_to(conn, 302) == ~p"/user/edit"
      assert flash(conn, :info) =~ ~r/revoked/
    end

    test "with other user's token shows error, redirects to settings", %{conn: conn} do
      user = insert(:user)
      api_token = insert(:api_token)
      conn = log_in(conn, user)

      conn = delete(conn, ~p"/api_tokens/#{api_token.id}")

      assert redirected_to(conn, 302) == ~p"/user/edit"
      assert flash(conn, :error) =~ ~r/not found/
    end

    test "with invalid token shows error, redirects to settings", %{conn: conn} do
      user = insert(:user)
      conn = log_in(conn, user)

      conn = delete(conn, ~p"/api_tokens/123456789")

      assert redirected_to(conn, 302) == ~p"/user/edit"
      assert flash(conn, :error) =~ ~r/not found/
    end
  end
end
