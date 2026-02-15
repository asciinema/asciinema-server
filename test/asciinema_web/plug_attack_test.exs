defmodule AsciinemaWeb.PlugAttackTest do
  use ExUnit.Case, async: false
  import Plug.Conn

  @storage AsciinemaWeb.PlugAttack.Storage

  @limits [
    login: [limit: 2, period: 60_000],
    search: [limit: 2, period: 60_000],
    view: [limit: 2, period: 60_000],
    create_recording: [limit: 2, period: 60_000],
    download_recording: [limit: 2, period: 60_000],
    create_stream: [limit: 2, period: 60_000],
    register_cli: [limit: 1, period: 60_000],
    default: [limit: 3, period: 60_000]
  ]

  setup do
    previous_config = Application.get_env(:asciinema, AsciinemaWeb.PlugAttack, [])
    Application.put_env(:asciinema, AsciinemaWeb.PlugAttack, limits: @limits)
    PlugAttack.Storage.Ets.clean(@storage)

    on_exit(fn ->
      PlugAttack.Storage.Ets.clean(@storage)
      Application.put_env(:asciinema, AsciinemaWeb.PlugAttack, previous_config)
    end)

    :ok
  end

  test "throttles login attempts" do
    assert_throttled_after("POST", "/login", 2)
  end

  test "throttles searches" do
    assert_throttled_after("GET", "/search", 2)
  end

  test "throttles recording downloads across .cast and .json" do
    ip = unique_ip()
    assert_allowed("GET", "/a/demo.cast", ip)
    assert_allowed("GET", "/a/demo.json", ip)

    conn = request("GET", "/a/demo.cast", ip)
    assert conn.status == 429
    assert conn.resp_body == "Too Many Requests\n"
    assert get_resp_header(conn, "x-ratelimit-limit") == ["2"]
    assert get_resp_header(conn, "x-ratelimit-remaining") == ["0"]
  end

  test "throttles view counting" do
    assert_throttled_after("POST", "/a/demo/views", 2)
  end

  test "throttles recording creation across both API endpoints" do
    ip = unique_ip()
    assert_allowed("POST", "/api/v1/recordings", ip)
    assert_allowed("POST", "/api/asciicasts", ip)

    conn = request("POST", "/api/v1/recordings", ip)
    assert conn.status == 429
    assert conn.resp_body == "Too Many Requests\n"
    assert get_resp_header(conn, "x-ratelimit-limit") == ["2"]
    assert get_resp_header(conn, "x-ratelimit-remaining") == ["0"]
  end

  test "throttles stream creation across both endpoints" do
    ip = unique_ip()
    assert_allowed("POST", "/user/streams", ip)
    assert_allowed("POST", "/api/v1/streams", ip)

    conn = request("POST", "/user/streams", ip)
    assert conn.status == 429
    assert conn.resp_body == "Too Many Requests\n"
    assert get_resp_header(conn, "x-ratelimit-limit") == ["2"]
    assert get_resp_header(conn, "x-ratelimit-remaining") == ["0"]
  end

  test "throttles CLI registrations" do
    assert_throttled_after("GET", "/connect/install-id", 1)
  end

  test "GET /login falls through to default rule" do
    assert_throttled_after("GET", "/login", 3)
  end

  test "GET /a/123 without extension falls through to default rule" do
    assert_throttled_after("GET", "/a/123", 3)
  end

  test "allows localhost without throttling" do
    ip = {127, 0, 0, 1}

    Enum.each(1..10, fn _ ->
      conn = request("GET", "/about", ip)
      assert is_nil(conn.status)
    end)
  end

  defp assert_throttled_after(method, path, limit) do
    ip = unique_ip()

    Enum.each(1..limit, fn _ ->
      assert_allowed(method, path, ip)
    end)

    conn = request(method, path, ip)
    assert conn.status == 429
    assert conn.resp_body == "Too Many Requests\n"
    assert get_resp_header(conn, "x-ratelimit-limit") == [Integer.to_string(limit)]
    assert get_resp_header(conn, "x-ratelimit-remaining") == ["0"]
    assert [reset] = get_resp_header(conn, "x-ratelimit-reset")
    assert String.to_integer(reset) > 0
  end

  defp assert_allowed(method, path, ip) do
    conn = request(method, path, ip)
    assert is_nil(conn.status)
    conn
  end

  defp request(method, path, remote_ip) do
    method
    |> Plug.Test.conn(path)
    |> Map.put(:remote_ip, remote_ip)
    |> AsciinemaWeb.PlugAttack.call([])
  end

  defp unique_ip do
    n = System.unique_integer([:positive])
    {10, rem(n, 256), rem(div(n, 256), 256), rem(div(n, 65536), 256)}
  end
end
