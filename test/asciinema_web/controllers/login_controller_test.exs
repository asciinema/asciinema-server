defmodule AsciinemaWeb.LoginControllerTest do
  use AsciinemaWeb.ConnCase, async: false
  import ExUnit.CaptureLog

  setup do
    logger_level = Logger.level()
    Logger.configure(level: :warning)

    on_exit(fn ->
      Logger.configure(level: logger_level)
    end)
  end

  describe "create" do
    test "logs bot honeypot fields without submitted login params", %{conn: conn} do
      log =
        capture_log([level: :warning], fn ->
          conn =
            post(conn, ~p"/login", %{
              "login" => %{
                "email" => "victim@example.com",
                "username" => "bot-filled",
                "terms" => "accepted"
              }
            })

          assert redirected_to(conn, 302) == ~p"/login/sent"
        end)

      assert log =~ "bot login attempt detected"
      assert log =~ "honeypot_fields=username,terms"
      refute log =~ "victim@example.com"
      refute log =~ "bot-filled"
      refute log =~ "accepted"
    end
  end
end
