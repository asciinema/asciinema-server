defmodule AsciinemaWeb.CliControllerTest do
  use AsciinemaWeb.ConnCase, async: true
  import Asciinema.Factory
  alias Asciinema.Accounts
  alias Asciinema.Recordings

  describe "show" do
    test "with unknown install_id does not register CLI", %{
      conn: conn
    } do
      user = insert(:user)
      conn = log_in(conn, user)

      conn = get(conn, ~p"/connect/00000000-0000-0000-0000-000000000000")

      assert html_response(conn, 200) =~ "Authenticate this CLI"

      assert Accounts.fetch_cli("00000000-0000-0000-0000-000000000000") ==
               {:error, :token_not_found}
    end

    test "with temporary user's install_id does not claim recordings", %{
      conn: conn
    } do
      user = insert(:user)
      tmp_user = insert(:temporary_user)
      cli = insert(:cli, user: tmp_user, token: "00000000-0000-0000-0000-000000000001")
      recording = insert(:asciicast, user: tmp_user)
      conn = log_in(conn, user)

      conn = get(conn, ~p"/connect/#{cli.token}")

      assert html_response(conn, 200) =~ "claim previous anonymous uploads"
      assert Recordings.get_asciicast(recording.id).user_id == tmp_user.id
    end
  end

  describe "create" do
    test "with unknown install_id registers CLI", %{conn: conn} do
      user = insert(:user)
      conn = log_in(conn, user)

      post(conn, ~p"/connect/00000000-0000-0000-0000-000000000000")

      assert {:ok, cli} = Accounts.fetch_cli("00000000-0000-0000-0000-000000000000")
      assert cli.user.id == user.id
    end

    test "with temporary user's install_id claims recordings", %{conn: conn} do
      user = insert(:user)
      tmp_user = insert(:temporary_user)
      cli = insert(:cli, user: tmp_user, token: "00000000-0000-0000-0000-000000000001")
      recording = insert(:asciicast, user: tmp_user)
      conn = log_in(conn, user)

      post(conn, ~p"/connect/#{cli.token}")

      assert Recordings.get_asciicast(recording.id).user_id == user.id
      assert {:ok, claimed_cli} = Accounts.fetch_cli(cli.token)
      assert claimed_cli.user.id == user.id
    end
  end

  describe "delete" do
    test "with other user's install_id shows error, redirects to settings", %{conn: conn} do
      user = insert(:user)
      cli = insert(:cli)
      conn = log_in(conn, user)

      conn = delete(conn, ~p"/clis/#{cli.id}")

      assert redirected_to(conn, 302) == ~p"/user/edit"
      assert flash(conn, :error) =~ ~r/not found/
    end

    test "with unknown install_id shows error, redirects to settings", %{conn: conn} do
      user = insert(:user)
      conn = log_in(conn, user)

      conn = delete(conn, ~p"/clis/123456789")

      assert redirected_to(conn, 302) == ~p"/user/edit"
      assert flash(conn, :error) =~ ~r/not found/
    end
  end
end
