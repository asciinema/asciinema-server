defmodule Asciinema.ApiTokenControllerTest do
  use AsciinemaWeb.ConnCase
  alias Asciinema.Accounts
  alias Asciinema.Accounts.User

  @revoked_token "eb927b31-9ca3-4a6a-8a0c-dfba318e2e84"
  @regular_user_token "c4ecd96a-9a16-464d-be6a-bc1f3c50c4ae"
  @other_regular_user_token "b26c2fe0-603b-4b10-b0fa-f6ec85628831"
  @tmp_user_token "863f6ae5-3f32-4ffc-8d47-284222d6225f"

  setup %{conn: conn} do
    {:ok, %User{}} = Accounts.get_user_with_api_token(@revoked_token, "revoked")
    @revoked_token |> Accounts.get_api_token! |> Accounts.revoke_api_token!

    regular_user = fixture(:user)
    {:ok, _} = Accounts.create_api_token(regular_user, @regular_user_token)

    other_regular_user = fixture(:user, %{username: "other", email: "other@example.com"})
    {:ok, _} = Accounts.create_api_token(other_regular_user, @other_regular_user_token)

    {:ok, %User{} = tmp_user} = Accounts.get_user_with_api_token(@tmp_user_token, "tmp")

    conn = login_as(conn, regular_user)

    {:ok, conn: conn, regular_user: regular_user, tmp_user: tmp_user}
  end

  test "as guest", %{conn: conn} do
    conn = logout(conn)
    conn = get conn, "/connect/#{@tmp_user_token}"
    assert redirected_to(conn, 302) == "/login/new"
    assert get_flash(conn, :info)
  end

  test "with invalid token", %{conn: conn} do
    conn = get conn, "/connect/nopenope"
    assert redirected_to(conn, 302) == "/"
    assert get_flash(conn, :error) =~ ~r/invalid token/i
  end

  test "with revoked token", %{conn: conn} do
    conn = get conn, "/connect/#{@revoked_token}"
    assert redirected_to(conn, 302) == "/"
    assert get_flash(conn, :error) =~ ~r/been revoked/i
  end

  test "with tmp user token", %{conn: conn} do
    conn = get conn, "/connect/#{@tmp_user_token}"
    assert redirected_to(conn, 302) == "/~test"
    assert get_flash(conn, :info)
  end

  test "with his own token", %{conn: conn} do
    conn = get conn, "/connect/#{@regular_user_token}"
    assert redirected_to(conn, 302) == "/~test"
    assert get_flash(conn, :info)
  end

  test "regular user with other regular user token", %{conn: conn} do
    conn = get conn, "/connect/#{@other_regular_user_token}"
    assert redirected_to(conn, 302) == "/~test"
    assert get_flash(conn, :error)
  end

  defp login_as(conn, user) do
    assign(conn, :current_user, user)
  end

  defp logout(conn) do
    assign(conn, :current_user, nil)
  end
end
