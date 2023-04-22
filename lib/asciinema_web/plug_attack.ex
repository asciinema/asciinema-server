defmodule AsciinemaWeb.PlugAttack do
  use PlugAttack
  import Plug.Conn

  rule "allow local", conn do
    allow(conn.remote_ip == {127, 0, 0, 1})
  end

  rule "throttle by ip", conn do
    if limit = config(:ip_limit) do
      throttle(conn.remote_ip,
        limit: limit,
        period: config(:ip_period),
        storage: {PlugAttack.Storage.Ets, AsciinemaWeb.PlugAttack.Storage}
      )
    end
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

  defp config(key) do
    Keyword.get(Application.get_env(:asciinema, __MODULE__, []), key)
  end
end
