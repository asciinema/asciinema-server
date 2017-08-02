defmodule Asciinema.SessionControllerTest do
  use AsciinemaWeb.ConnCase
  alias Asciinema.Users
  alias Asciinema.Users.{User, ApiToken}

  @revoked_token "eb927b31-9ca3-4a6a-8a0c-dfba318e2e84"
  @regular_user_token "c4ecd96a-9a16-464d-be6a-bc1f3c50c4ae"
  @other_regular_user_token "b26c2fe0-603b-4b10-b0fa-f6ec85628831"
  @tmp_user_token "863f6ae5-3f32-4ffc-8d47-284222d6225f"
  @other_tmp_user_token "2eafaa20-80c8-47fc-b014-74072027edae"

  setup %{conn: conn} do
    {:ok, %User{}} = Users.get_user_with_api_token(@revoked_token, "revoked")
    @revoked_token |> Users.get_api_token! |> Users.revoke_api_token!

    regular_user = fixture(:user)
    ApiToken.create_changeset(regular_user, @regular_user_token) |> Repo.insert!

    other_regular_user = fixture(:user, %{username: "other", email: "other@example.com"})
    ApiToken.create_changeset(other_regular_user, @other_regular_user_token) |> Repo.insert!

    {:ok, %User{} = tmp_user} = Users.get_user_with_api_token(@tmp_user_token, "tmp")

    {:ok, %User{}} = Users.get_user_with_api_token(@other_tmp_user_token, "other_tmp")

    {:ok, conn: conn, regular_user: regular_user, tmp_user: tmp_user}
  end

  test "invalid token", %{conn: conn} do
    conn = get conn, "/connect/nopenope"
    assert redirected_to(conn, 302) == "/"
    assert get_rails_flash(conn, :alert) =~ ~r/invalid token/i
  end

  test "revoked token", %{conn: conn} do
    conn = get conn, "/connect/#{@revoked_token}"
    assert redirected_to(conn, 302) == "/"
    assert get_rails_flash(conn, :alert) =~ ~r/been revoked/i
  end

  test "guest with tmp user token", %{conn: conn} do
    conn = get conn, "/connect/#{@tmp_user_token}"
    assert redirected_to(conn, 302) == "/user/edit"
    assert get_rails_flash(conn, :notice) =~ ~r/welcome.+username.+email/i
  end

  test "guest with regular user token", %{conn: conn} do
    conn = get conn, "/connect/#{@regular_user_token}"
    assert redirected_to(conn, 302) == "/~test"
    assert get_rails_flash(conn, :notice) =~ ~r/welcome back/i
  end

  test "tmp user with his own token", %{conn: conn, tmp_user: user} do
    conn = login_as(conn, user)
    conn = get conn, "/connect/#{@tmp_user_token}"
    assert redirected_to(conn, 302) == "/user/edit"
    assert get_rails_flash(conn, :notice)
  end

  test "tmp user with other tmp user token", %{conn: conn, tmp_user: user} do
    conn = login_as(conn, user)
    conn = get conn, "/connect/#{@other_tmp_user_token}"
    assert redirected_to(conn, 302) == "/user/edit"
    assert get_rails_flash(conn, :notice)
  end

  test "tmp user with other regular user token", %{conn: conn, tmp_user: user} do
    conn = login_as(conn, user)
    conn = get conn, "/connect/#{@regular_user_token}"
    assert redirected_to(conn, 302) == "/~test"
    assert get_rails_flash(conn, :notice)
  end

  test "regular user with other tmp user token", %{conn: conn, regular_user: user} do
    conn = login_as(conn, user)
    conn = get conn, "/connect/#{@tmp_user_token}"
    assert redirected_to(conn, 302) == "/~test"
    assert get_rails_flash(conn, :notice)
  end

  test "regular user with his own token", %{conn: conn, regular_user: user} do
    conn = login_as(conn, user)
    conn = get conn, "/connect/#{@regular_user_token}"
    assert redirected_to(conn, 302) == "/~test"
    assert get_rails_flash(conn, :notice)
  end

  test "regular user with other regular user token", %{conn: conn, regular_user: user} do
    conn = login_as(conn, user)
    conn = get conn, "/connect/#{@other_regular_user_token}"
    assert redirected_to(conn, 302) == "/~test"
    assert get_rails_flash(conn, :alert)
  end

  defp get_rails_flash(conn, key) do
    conn
    |> get_session(:flash)
    |> get_in([:flashes, key])
  end

  defp login_as(conn, user) do
    assign(conn, :current_user, user)
  end

end
