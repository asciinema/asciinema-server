defmodule AsciinemaWeb.Api.StreamController do
  use AsciinemaWeb, :controller
  alias Asciinema.{Accounts, Streaming}

  plug :authenticate
  plug :check_streaming_enabled
  plug :load_stream when action in [:update, :delete]
  plug :authorize, :stream when action in [:update, :delete]

  @default_index_limit 10

  def index(conn, %{"cursor" => cursor} = params) when is_binary(cursor) do
    {stream_id, prefix} = decode_cursor(cursor)
    paginate(conn, stream_id, prefix, params["limit"])
  end

  def index(conn, params) do
    paginate(conn, nil, params["prefix"], params["limit"])
  end

  defp paginate(conn, stream_id, prefix, limit) do
    limit = if limit, do: String.to_integer(limit), else: @default_index_limit

    result =
      [user_id: conn.assigns.current_user.id, prefix: prefix]
      |> Streaming.query(:id)
      |> Streaming.cursor_paginate(stream_id, limit)

    conn
    |> put_pagination_header(result, prefix, limit)
    |> render(:index, streams: result.entries)
  end

  def show(conn, %{"id" => id}) do
    conn.assigns.current_user
    |> Streaming.fetch_stream(id)
    |> render_stream(conn, id)
  end

  def create(conn, _params) do
    case Streaming.create_stream(conn.assigns.current_user) do
      {:ok, stream} ->
        render(conn, :show, stream: stream)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, reason: changeset)
    end
  end

  def update(conn, params) do
    case Streaming.update_stream(conn.assigns.stream, params) do
      {:ok, stream} ->
        render(conn, :show, stream: stream)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, reason: changeset)
    end
  end

  def delete(conn, _params) do
    {:ok, _} = Streaming.delete_stream(conn.assigns.stream)

    conn
    |> put_status(:no_content)
    |> render(:deleted)
  end

  defp render_stream({:ok, stream}, conn, _id) do
    render(conn, :show, stream: stream)
  end

  defp render_stream({:error, :not_found}, conn, id) do
    conn
    |> put_status(:not_found)
    |> render(:error, reason: "stream #{id} not found")
  end

  defp render_stream({:error, :limit_reached}, conn, _id) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(:error, reason: "live stream limit exceeded")
  end

  defp authenticate(conn, _opts) do
    with {_username, token} <- get_basic_auth(conn),
         {:ok, cli} <- Accounts.fetch_cli(token),
         true <- Accounts.cli_registered?(cli) do
      assign(conn, :current_user, cli.user)
    else
      _otherwise ->
        conn
        |> put_status(:unauthorized)
        |> json(%{})
        |> halt()
    end
  end

  defp check_streaming_enabled(conn, _opts) do
    if conn.assigns.current_user.streaming_enabled do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> render(:error, reason: "streaming disabled")
      |> halt()
    end
  end

  defp load_stream(conn, _opts) do
    case Streaming.lookup_stream(conn.params["id"]) do
      nil ->
        conn
        |> put_status(:not_found)
        |> render(:error, reason: "stream not found")
        |> halt()

      stream ->
        assign(conn, :stream, stream)
    end
  end

  defp put_pagination_header(conn, %{has_more: true, last_id: stream_id}, prefix, limit) do
    cursor = encode_cursor(stream_id, prefix)
    next_url = url(~p"/api/v1/user/streams?cursor=#{cursor}&limit=#{limit}")
    put_resp_header(conn, "link", ~s(<#{next_url}>; rel="next"))
  end

  defp put_pagination_header(conn, _result, _prefix, _params), do: conn

  defp encode_cursor(stream_id, prefix) do
    %{id: stream_id, prefix: prefix}
    |> Jason.encode!()
    |> Base.encode64()
  end

  defp decode_cursor(cursor) do
    %{"id" => stream_id, "prefix" => prefix} =
      cursor
      |> Base.decode64!()
      |> Jason.decode!()

    {stream_id, prefix}
  end
end
