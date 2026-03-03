defmodule Asciinema.HttpUtilTest do
  use ExUnit.Case, async: true
  alias Asciinema.HttpUtil

  test "download_to/2 saves uncompressed response" do
    body = ~s({"version": 2, "stdout": "hello"}\n)
    %{base_url: base_url} = start_server(response: {:plain, body})
    path = Briefly.create!()

    assert :ok == HttpUtil.download_to(base_url <> "/plain.cast", path)
    assert File.read!(path) == body
  end

  test "download_to/2 saves decompressed gzip response" do
    body = ~s({"version": 2, "stdout": "hello"}\n)
    %{base_url: base_url} = start_server(response: {:gzip, body})
    path = Briefly.create!()

    assert :ok == HttpUtil.download_to(base_url <> "/gzip.cast", path)
    assert File.read!(path) == body
  end

  test "download_to/2 returns normalized error on non-200 response" do
    %{base_url: base_url} = start_server(response: {:status, 404, "missing"})
    path = Briefly.create!()

    assert {:error, {:http_status, 404}} ==
             HttpUtil.download_to(base_url <> "/missing.cast", path)

    refute File.exists?(path)
  end

  test "download_to/2 returns normalized error on partial content response" do
    %{base_url: base_url} = start_server(response: {:partial, "part", 10})
    path = Briefly.create!()

    assert {:error, {:http_status, 206}} ==
             HttpUtil.download_to(base_url <> "/partial.cast", path)

    refute File.exists?(path)
  end

  defp start_server(opts) do
    server =
      start_supervised!(
        {Bandit,
         plug: {__MODULE__.MockServer, %{response: Keyword.fetch!(opts, :response)}},
         scheme: :http,
         ip: {127, 0, 0, 1},
         port: 0}
      )

    {:ok, {{127, 0, 0, 1}, port}} = ThousandIsland.listener_info(server)

    %{base_url: "http://127.0.0.1:#{port}"}
  end

  defmodule MockServer do
    import Plug.Conn

    def init(opts), do: opts

    def call(conn, opts) do
      case opts.response do
        {:plain, body} ->
          conn
          |> put_resp_content_type("application/x-asciicast")
          |> send_resp(200, body)

        {:gzip, body} ->
          conn
          |> put_resp_content_type("application/x-asciicast")
          |> put_resp_header("content-encoding", "gzip")
          |> send_resp(200, :zlib.gzip(body))

        {:partial, body, total_size} ->
          end_byte = byte_size(body) - 1

          conn
          |> put_resp_content_type("application/x-asciicast")
          |> put_resp_header("content-range", "bytes 0-#{end_byte}/#{total_size}")
          |> send_resp(206, body)

        {:status, status, body} ->
          send_resp(conn, status, body)
      end
    end
  end
end
