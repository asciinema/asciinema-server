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

  test "download_to/2 requests gzip encoding by default" do
    %{base_url: base_url} = start_server(response: :echo_accept_encoding)
    path = Briefly.create!()

    assert :ok == HttpUtil.download_to(base_url <> "/headers.cast", path)
    assert File.read!(path) == "gzip"
  end

  test "download_to/2 saves decompressed gzip response" do
    body = ~s({"version": 2, "stdout": "hello"}\n)
    %{base_url: base_url} = start_server(response: {:gzip, body})
    path = Briefly.create!()

    assert :ok == HttpUtil.download_to(base_url <> "/gzip.cast", path)
    assert File.read!(path) == body
  end

  test "download_to/3 preserves gzip response when decompress is false" do
    body = ~s({"version": 2, "stdout": "hello"}\n)
    %{base_url: base_url} = start_server(response: {:gzip, body})
    path = Briefly.create!()

    assert :ok == HttpUtil.download_to(base_url <> "/gzip.cast", path, decompress: false)
    assert File.read!(path) == :zlib.gzip(body)
  end

  test "download_to/3 requests identity encoding when decompress is false" do
    %{base_url: base_url} = start_server(response: :echo_accept_encoding)
    path = Briefly.create!()

    assert :ok == HttpUtil.download_to(base_url <> "/headers.cast", path, decompress: false)
    assert File.read!(path) == "identity"
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
    ref = make_ref()

    _server =
      start_supervised!(
        {Plug.Cowboy,
         ref: ref,
         scheme: :http,
         plug: {__MODULE__.MockServer, %{response: Keyword.fetch!(opts, :response)}},
         options: [ip: {127, 0, 0, 1}, port: 0]}
      )

    {{127, 0, 0, 1}, port} = :ranch.get_addr(ref)

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

        :echo_accept_encoding ->
          accept_encoding =
            conn
            |> get_req_header("accept-encoding")
            |> List.first("")

          conn
          |> put_resp_content_type("text/plain")
          |> send_resp(200, accept_encoding)

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
