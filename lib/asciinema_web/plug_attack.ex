defmodule AsciinemaWeb.PlugAttack do
  use PlugAttack
  import Plug.Conn

  @storage {PlugAttack.Storage.Ets, AsciinemaWeb.PlugAttack.Storage}

  rule "allow local", conn do
    allow(conn.remote_ip == {127, 0, 0, 1})
  end

  rule "throttle login attempts", conn do
    if conn.method == "POST" and conn.path_info == ["login"] do
      throttle({:login, conn.remote_ip}, limit_for(:login))
    end
  end

  rule "throttle searches", conn do
    if conn.method == "GET" and conn.path_info == ["search"] do
      throttle({:search, conn.remote_ip}, limit_for(:search))
    end
  end

  rule "throttle recording download", conn do
    if conn.method == "GET" do
      case conn.path_info do
        ["a", id] ->
          if String.ends_with?(id, ".cast") || String.ends_with?(id, ".json") do
            throttle({:download_recording, conn.remote_ip}, limit_for(:download_recording))
          end

        _ ->
          nil
      end
    end
  end

  rule "throttle view counting", conn do
    if conn.method == "POST" and match?(["a", _, "views"], conn.path_info) do
      throttle({:view, conn.remote_ip}, limit_for(:view))
    end
  end

  rule "throttle recording creation", conn do
    if conn.method == "POST" and
         conn.path_info in [["api", "v1", "recordings"], ["api", "asciicasts"]] do
      throttle({:create_recording, conn.remote_ip}, limit_for(:create_recording))
    end
  end

  rule "throttle stream creation", conn do
    if conn.method == "POST" and conn.path_info in [["user", "streams"], ["api", "v1", "streams"]] do
      throttle({:create_stream, conn.remote_ip}, limit_for(:create_stream))
    end
  end

  rule "throttle CLI registrations", conn do
    if conn.method == "GET" and match?(["connect", _], conn.path_info) do
      throttle({:register_cli, conn.remote_ip}, limit_for(:register_cli))
    end
  end

  rule "throttle everything else by ip", conn do
    throttle({:default, conn.remote_ip}, limit_for(:default))
  end

  def block_action(conn, {:throttle, data}, _opts) do
    reset = div(data[:expires_at], 1_000)

    conn
    |> put_resp_header("x-ratelimit-limit", to_string(data[:limit]))
    |> put_resp_header("x-ratelimit-remaining", to_string(data[:remaining]))
    |> put_resp_header("x-ratelimit-reset", to_string(reset))
    |> send_resp(429, "Too Many Requests\n")
    |> halt()
  end

  def block_action(conn, _data, _opts) do
    conn
    |> send_resp(:forbidden, "Forbidden\n")
    |> halt()
  end

  @default_limits [
    login: [limit: 5, period: 60_000],
    search: [limit: 30, period: 60_000],
    view: [limit: 10, period: 10_000],
    create_recording: [limit: 10, period: 60_000],
    download_recording: [limit: 30, period: 60_000],
    create_stream: [limit: 10, period: 60_000],
    register_cli: [limit: 3, period: 60_000],
    default: [limit: 50, period: 10_000]
  ]

  defp limit_for(request) do
    overrides = config(:limits, [])
    limit = Keyword.get(overrides, request) || Keyword.fetch!(@default_limits, request)

    limit ++ [{:storage, @storage}]
  end

  defp config(key, default) do
    Keyword.get(Application.get_env(:asciinema, __MODULE__, []), key, default)
  end
end
