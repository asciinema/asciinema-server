defmodule AsciinemaWeb.CachingTest do
  use ExUnit.Case, async: true

  import Plug.Test

  alias AsciinemaWeb.Caching

  test "put_etag stores a quoted etag" do
    conn =
      :get
      |> conn("/")
      |> Caching.put_etag("abc")

    assert [etag] = Plug.Conn.get_resp_header(conn, "etag")
    assert String.starts_with?(etag, "\"")
    assert String.ends_with?(etag, "\"")
  end

  test "fresh?/1 matches if-none-match header values" do
    conn =
      :get
      |> conn("/")
      |> Plug.Conn.put_req_header("if-none-match", "\"foo\", \"bar\"")
      |> Plug.Conn.put_resp_header("etag", "\"bar\"")

    assert Caching.fresh?(conn)
  end

  test "fresh?/1 supports wildcard and returns false when missing etag" do
    wildcard_conn =
      :get
      |> conn("/")
      |> Plug.Conn.put_req_header("if-none-match", "*")
      |> Plug.Conn.put_resp_header("etag", "\"anything\"")

    assert Caching.fresh?(wildcard_conn)
    refute Caching.fresh?(conn(:get, "/"))
  end

  test "fresh?/1 treats weak and strong etags as equivalent" do
    weak_request_conn =
      :get
      |> conn("/")
      |> Plug.Conn.put_req_header("if-none-match", ~s(W/"bar"))
      |> Plug.Conn.put_resp_header("etag", ~s("bar"))

    strong_request_conn =
      :get
      |> conn("/")
      |> Plug.Conn.put_req_header("if-none-match", ~s("bar"))
      |> Plug.Conn.put_resp_header("etag", ~s(W/"bar"))

    assert Caching.fresh?(weak_request_conn)
    assert Caching.fresh?(strong_request_conn)
  end
end
