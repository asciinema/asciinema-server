defmodule Asciinema.WebFingerControllerTest do
  use AsciinemaWeb.ConnCase
  import Asciinema.Factory

  setup [:create_user]

  describe "show" do
    test "returns basic info", %{conn: conn} do
      conn = get(conn, ~p"/.well-known/webfinger?resource=acct:Pinky@localhost")

      assert json_response(conn, 200) == %{
               "subject" => "acct:Pinky@localhost",
               "aliases" => [
                 url(~p"/~Pinky")
               ],
               "links" => [
                 %{
                   "rel" => "http://webfinger.net/rel/profile-page",
                   "type" => "text/html",
                   "href" => url(~p"/~Pinky")
                 }
               ]
             }
    end

    test "does case-insensitive acct lookup", %{conn: conn} do
      conn = get(conn, ~p"/.well-known/webfinger?resource=acct:pinky@lOcaLhOst")

      assert %{"subject" => "acct:Pinky@localhost"} = json_response(conn, 200)
    end

    test "returns 404 when username not found", %{conn: conn} do
      conn = get(conn, ~p"/.well-known/webfinger?resource=acct:nope@localhost")

      assert json_response(conn, 404)
    end

    test "returns 404 when domain doesn't match", %{conn: conn} do
      conn = get(conn, ~p"/.well-known/webfinger?resource=acct:pinky@nope.nope")

      assert json_response(conn, 404)
    end
  end

  defp create_user(_) do
    %{user: insert(:user, username: "Pinky")}
  end
end
