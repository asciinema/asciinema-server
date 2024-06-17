defmodule Asciinema.ApiTokenControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory
  alias Asciinema.Accounts

  @revoked_token "eb927b31-9ca3-4a6a-8a0c-dfba318e2e84"
  @regular_user_token "c4ecd96a-9a16-464d-be6a-bc1f3c50c4ae"
  @other_regular_user_token "b26c2fe0-603b-4b10-b0fa-f6ec85628831"
  @tmp_user_token "863f6ae5-3f32-4ffc-8d47-284222d6225f"

  setup %{conn: conn} do
    {:ok, _} = Accounts.get_user_with_api_token(@revoked_token, "revoked")
    @revoked_token |> Accounts.get_api_token!() |> Accounts.revoke_api_token!()
    user = insert(:user, username: "test")
    {:ok, _} = Accounts.create_api_token(user, @regular_user_token)
    other_regular_user = insert(:user)
    {:ok, _} = Accounts.create_api_token(other_regular_user, @other_regular_user_token)
    {:ok, tmp_user} = Accounts.get_user_with_api_token(@tmp_user_token, "tmp")

    {:ok, conn: conn, user: user, tmp_user: tmp_user}
  end

  describe "register" do
    test "as guest redirects to login page", %{conn: conn} do
      conn = get(conn, ~p"/connect/#{@tmp_user_token}")

      assert redirected_to(conn, 302) == ~p"/login/new"
      assert flash(conn, :info)
    end

    test "with invalid token shows error", %{conn: conn, user: user} do
      conn = log_in(conn, user)

      conn = get(conn, ~p"/connect/nopenope")

      assert redirected_to(conn, 302) == "/"
      assert flash(conn, :error) =~ ~r/invalid/i
    end

    test "with revoked token shows error", %{conn: conn, user: user} do
      conn = log_in(conn, user)

      conn = get(conn, ~p"/connect/#{@revoked_token}")

      assert redirected_to(conn, 302) == "/"
      assert flash(conn, :error) =~ ~r/been revoked/i
    end

    test "with tmp user token shows notice, redirects to profile page", %{conn: conn, user: user} do
      conn = log_in(conn, user)

      conn = get(conn, ~p"/connect/#{@tmp_user_token}")

      assert redirected_to(conn, 302) == ~p"/~test"
      assert flash(conn, :info) =~ ~r/successfully/
    end

    test "with their own token shows notice, redirects to profile page", %{conn: conn, user: user} do
      conn = log_in(conn, user)

      conn = get(conn, ~p"/connect/#{@regular_user_token}")

      assert redirected_to(conn, 302) == ~p"/~test"
      assert flash(conn, :info) =~ ~r/successfully/
    end

    test "with other user's token shows error, redirects to profile page", %{conn: conn, user: user} do
      conn = log_in(conn, user)

      conn = get(conn, ~p"/connect/#{@other_regular_user_token}")

      assert redirected_to(conn, 302) == ~p"/~test"
      assert flash(conn, :error) =~ ~r/different/
    end
  end
end
