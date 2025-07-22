defmodule AsciinemaWeb.Features.ClisTest do
  use AsciinemaWeb.FeatureCase, async: true

  describe "CLI registration" do
    test "when logged in, new unregistered CLI", %{conn: conn} do
      user = insert(:user, username: "foobar")

      conn
      |> log_in_user(user)
      |> visit("/connect/00000000-0000-0000-0000-000000000000")
      |> assert_has(".flash", text: "successfully")
      |> click_link("Settings")
      |> assert_has("table", text: "00000000-0000-0000-0000-000000000000")
    end

    test "when logged in, existing unregistered CLI", %{conn: conn} do
      user = insert(:user, username: "foobar")
      cli = insert(:cli, user: user)

      conn
      |> log_in_user(user)
      |> visit("/connect/#{cli.token}")
      |> assert_has(".flash", text: "successfully")
      |> click_link("Settings")
      |> assert_has("table", text: cli.token)
    end

    test "when not logged in, new user", %{conn: conn} do
      conn
      |> visit("/connect/00000000-0000-0000-0000-000000000000")
      |> assert_path("/login/new")
      |> assert_has(".flash", text: "log in first")
      |> fill_in("E-mail or username", with: "test@example.com")
      |> click_button("Log in")
      |> visit(link_from_email())
      |> verify_magic_link()
      |> assert_has(".flash", text: "successfully")
      |> click_link("I'll do it later")
      |> click_link("Settings")
      |> assert_has("table", text: "00000000-0000-0000-0000-000000000000")
    end

    test "when not logged in, existing user", %{conn: conn} do
      insert(:user, username: "foobar")

      conn
      |> visit("/connect/00000000-0000-0000-0000-000000000000")
      |> assert_path("/login/new")
      |> assert_has(".flash", text: "log in first")
      |> fill_in("E-mail or username", with: "foobar")
      |> click_button("Log in")
      |> visit(link_from_email())
      |> verify_magic_link()
      |> assert_has(".flash", text: "successfully")
      |> click_link("Settings")
      |> assert_has("table", text: "00000000-0000-0000-0000-000000000000")
    end

    test "invalid installation ID", %{conn: conn} do
      user = insert(:user)

      conn
      |> log_in_user(user)
      |> visit("/connect/invalid-id")
      |> assert_path("/")
      |> assert_has(".flash", text: "Invalid installation ID")
    end

    test "revoked CLI", %{conn: conn} do
      user = insert(:user)
      cli = insert(:revoked_cli, user: user)

      conn
      |> log_in_user(user)
      |> visit("/connect/#{cli.token}")
      |> assert_path("/")
      |> assert_has(".flash", text: "been revoked")
    end

    test "CLI owned by another user", %{conn: conn} do
      user = insert(:user)
      cli = insert(:cli, user: insert(:user))

      conn
      |> log_in_user(user)
      |> visit("/connect/#{cli.token}")
      |> assert_has(".flash", text: "different user")
    end

    test "CLI owned by a temporary user", %{conn: conn} do
      user = insert(:user)
      cli = insert(:cli, user: insert(:temporary_user))

      conn
      |> log_in_user(user)
      |> visit("/connect/#{cli.token}")
      |> assert_has(".flash", text: "successfully")
    end
  end

  describe "CLI listing and management" do
    test "requires authentication", %{conn: conn} do
      conn
      |> visit("/user/edit")
      |> assert_path("/login/new")
      |> assert_has(".flash", text: "log in first")
    end

    test "complete flow", %{conn: conn} do
      user = insert(:user)
      active_cli = insert(:cli, user: user)
      revoked_cli = insert(:revoked_cli, user: user)
      other_user_cli = insert(:cli)

      conn
      |> log_in_user(user)
      |> visit("/")
      |> click_link("Settings")
      |> assert_has("code", text: "asciinema auth")
      |> assert_has("tr:nth-child(1)", text: active_cli.token)
      |> assert_has("tr:nth-child(1) a", text: "Revoke")
      |> assert_has("tr:nth-child(2)", text: revoked_cli.token)
      |> assert_has("tr:nth-child(2)", text: "Revoked")
      |> refute_has("tr", text: other_user_cli.token)
      |> click_link("Revoke")
      |> assert_has(".flash", text: "revoked")
      |> refute_has("tr a", text: "Revoke")
    end
  end
end
