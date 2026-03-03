defmodule Asciinema.HttpUtil do
  @default_connect_timeout 5_000
  @default_timeout 15_000

  def download_to(url, path, http_options \\ []) do
    url = String.to_charlist(url)

    http_options =
      Keyword.merge(
        [
          connect_timeout: @default_connect_timeout,
          timeout: @default_timeout,
          autoredirect: true,
          ssl: [verify: :verify_peer, cacerts: :public_key.cacerts_get()]
        ],
        http_options
      )

    timeout = Keyword.fetch!(http_options, :timeout)
    request_options = [sync: false, stream: :self, body_format: :binary]

    case :httpc.request(:get, {url, []}, http_options, request_options) do
      {:ok, req_id} ->
        case File.open(path, [:write, :binary]) do
          {:ok, io} ->
            result =
              try do
                recv_stream(req_id, io, timeout, nil)
              after
                File.close(io)
              end

            finalize_stream(path, req_id, result)

          {:error, reason} ->
            finalize_request(req_id, nil, true)
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp recv_stream(req_id, io, timeout, inflater) do
    receive do
      {:http, {^req_id, :stream_start, headers}} ->
        if partial_content?(headers) do
          {:error, {:http_status, 206}, inflater, true}
        else
          case maybe_open_inflater(headers) do
            {:ok, inflater} -> recv_stream(req_id, io, timeout, inflater)
            {:error, reason, inflater} -> {:error, reason, inflater, true}
          end
        end

      {:http, {^req_id, :stream, chunk}} ->
        case write_chunk(io, inflater, chunk) do
          :ok -> recv_stream(req_id, io, timeout, inflater)
          {:error, reason} -> {:error, reason, inflater, true}
        end

      {:http, {^req_id, :stream_end, _headers}} ->
        case finish_inflater(io, inflater) do
          :ok -> {:ok, inflater}
          {:error, reason} -> {:error, reason, inflater, false}
        end

      # Depending on :httpc/:inets internals (or adapters), non-200 responses can
      # arrive in a few tuple shapes. Handle all known variants defensively.
      {:http, {^req_id, {{_v, status, _reason}, _headers, _body}}} ->
        {:error, {:http_status, status}, inflater, false}

      {:http, {^req_id, {:ok, {{_v, status, _reason}, _headers, _body}}}} ->
        {:error, {:http_status, status}, inflater, false}

      {:http, {^req_id, {status, _body}}} when is_integer(status) ->
        {:error, {:http_status, status}, inflater, false}

      {:http, {^req_id, {:ok, {status, _body}}}} when is_integer(status) ->
        {:error, {:http_status, status}, inflater, false}

      {:http, {^req_id, {:error, reason}}} ->
        {:error, reason, inflater, false}
    after
      timeout -> {:error, {:timeout, timeout}, inflater, true}
    end
  end

  defp finalize_stream(path, req_id, result) do
    case result do
      {:ok, inflater} ->
        finalize_request(req_id, inflater, false)
        :ok

      {:error, reason, inflater, cancel?} ->
        finalize_request(req_id, inflater, cancel?)
        _ = File.rm(path)
        {:error, reason}
    end
  end

  defp partial_content?(headers) do
    Enum.any?(headers, fn {name, _value} ->
      String.downcase(to_string(name)) == "content-range"
    end)
  end

  defp gzip_encoded?(headers) do
    Enum.any?(headers, fn {name, value} ->
      String.downcase(to_string(name)) == "content-encoding" and
        String.contains?(String.downcase(to_string(value)), "gzip")
    end)
  end

  defp maybe_open_inflater(headers) do
    if gzip_encoded?(headers) do
      inflater = :zlib.open()

      try do
        :ok = :zlib.inflateInit(inflater, 31)
        {:ok, inflater}
      catch
        :error, reason -> {:error, reason, inflater}
      end
    else
      {:ok, nil}
    end
  end

  defp write_chunk(io, nil, chunk), do: safe_binwrite(io, chunk)

  defp write_chunk(io, inflater, chunk) do
    case inflate(inflater, chunk) do
      {:ok, data} -> safe_binwrite(io, data)
      {:error, reason} -> {:error, reason}
    end
  end

  defp finish_inflater(_io, nil), do: :ok

  defp finish_inflater(io, inflater) do
    # Feed an empty chunk once to drain any pending inflater output.
    case inflate(inflater, <<>>) do
      {:ok, data} -> safe_binwrite(io, data)
      {:error, reason} -> {:error, reason}
    end
  end

  defp inflate(inflater, data) do
    try do
      {:ok, :zlib.inflate(inflater, data)}
    catch
      :error, reason -> {:error, reason}
    end
  end

  defp safe_binwrite(io, data) do
    try do
      IO.binwrite(io, data)
    catch
      :error, reason -> {:error, reason}
    end
  end

  defp close_inflater(nil), do: :ok

  defp close_inflater(inflater) do
    try do
      :zlib.inflateEnd(inflater)
    catch
      _, _ -> :ok
    end

    :zlib.close(inflater)
  end

  defp finalize_request(req_id, inflater, cancel?) do
    if cancel? do
      cancel_request(req_id)
    end

    close_inflater(inflater)
  end

  defp cancel_request(req_id) do
    :httpc.cancel_request(req_id)
    flush_response(req_id)
  end

  defp flush_response(req_id) do
    receive do
      {:http, {^req_id, _}} ->
        flush_response(req_id)

      {:http, {^req_id, _, _}} ->
        flush_response(req_id)

      {:http, {^req_id, _, _, _}} ->
        flush_response(req_id)
    after
      0 ->
        :ok
    end
  end
end
