defmodule AsciinemaAdmin.StreamControllerTest do
  use AsciinemaAdmin.ConnCase, async: true

  alias Asciinema.Repo
  alias Asciinema.Streaming.Stream

  describe "GET /admin/streams" do
    test "lists streams of every visibility", %{conn: conn} do
      insert(:stream, title: "alpha-stream", visibility: :private)
      insert(:stream, title: "beta-stream", visibility: :public)

      body = conn |> get(~p"/admin/streams") |> html_response(200)

      assert body =~ "alpha-stream"
      assert body =~ "beta-stream"
    end

    test "filters by live", %{conn: conn} do
      insert(:stream, title: "i-am-live", live: true)
      insert(:stream, title: "im-offline", live: false)

      body = conn |> get(~p"/admin/streams?live=yes") |> html_response(200)

      assert body =~ "i-am-live"
      refute body =~ "im-offline"
    end
  end

  describe "GET /admin/streams/:id" do
    test "renders the stream show page with player and recordings list", %{conn: conn} do
      stream = insert(:stream, title: "demo-stream")
      asciicast = insert(:asciicast, stream_id: stream.id, title: "recorded-from-stream")
      _unrelated = insert(:asciicast, title: "no-stream-link")

      body = conn |> get(~p"/admin/streams/#{stream.id}") |> html_response(200)

      assert body =~ "demo-stream"
      assert body =~ "Tokens"
      assert body =~ ~s(id="player")
      assert body =~ "/ws/s/#{stream.public_token}"
      assert body =~ "Recordings from this stream"
      assert body =~ "recorded-from-stream"
      refute body =~ "no-stream-link"
      assert body =~ "/admin/recordings/#{asciicast.id}"
      assert body =~ "Delete stream"
    end
  end

  describe "PUT /admin/streams/:id" do
    test "updates the stream", %{conn: conn} do
      stream = insert(:stream, title: "Old")

      conn =
        put(conn, ~p"/admin/streams/#{stream.id}", %{
          "stream" => %{"title" => "New title"}
        })

      assert redirected_to(conn) == ~p"/admin/streams/#{stream.id}"
      assert Repo.get!(Stream, stream.id).title == "New title"
    end

    test "rerenders edit form on validation failure (invalid cron schedule)",
         %{conn: conn} do
      stream = insert(:stream, title: "Keep me", schedule: nil)

      conn =
        put(conn, ~p"/admin/streams/#{stream.id}", %{
          "stream" => %{"schedule" => "this is not a cron expression"}
        })

      assert html_response(conn, 200) =~ "Edit stream"
      assert Repo.get!(Stream, stream.id).title == "Keep me"
      assert Repo.get!(Stream, stream.id).schedule == nil
    end
  end

  describe "DELETE /admin/streams/:id" do
    test "deletes the stream", %{conn: conn} do
      stream = insert(:stream)

      conn = delete(conn, ~p"/admin/streams/#{stream.id}")

      assert redirected_to(conn) == ~p"/admin/streams"
      refute Repo.get(Stream, stream.id)
    end
  end

  describe "POST /admin/streams/:id/disconnect" do
    test "flashes 'not running' when no GenServer is registered", %{conn: conn} do
      stream = insert(:stream)

      conn = post(conn, ~p"/admin/streams/#{stream.id}/disconnect", %{})

      assert redirected_to(conn) == ~p"/admin/streams/#{stream.id}"
      assert flash(conn, :info) =~ "not running"
    end
  end
end
