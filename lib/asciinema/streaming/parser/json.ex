defmodule Asciinema.Streaming.Parser.Json do
  @behaviour Asciinema.Streaming.Parser

  def init, do: %{first: true}

  def parse({"\n", _opts}, state), do: {:ok, [], state}

  def parse({payload, _opts}, state) do
    case Jason.decode(payload) do
      {:ok, message} ->
        handle_message(message, state)

      {:error, %Jason.DecodeError{} = reason} ->
        {:error, "JSON decode error: #{Jason.DecodeError.message(reason)}"}
    end
  end

  def handle_message(%{"cols" => cols, "rows" => rows} = header, state)
      when is_integer(cols) and is_integer(rows) do
    commands = [reset: %{size: {cols, rows}, init: header["init"], time: header["time"]}]

    {:ok, commands, %{state | first: false}}
  end

  def handle_message(%{"width" => cols, "height" => rows}, state)
      when is_integer(cols) and is_integer(rows) do
    commands = [reset: %{size: {cols, rows}, init: nil, time: nil}]

    {:ok, commands, %{state | first: false}}
  end

  def handle_message(_message, %{first: true}) do
    {:error, :reset_expected}
  end

  def handle_message([time, "o", data], state) when is_number(time) and is_binary(data) do
    {:ok, [feed: {time, data}], state}
  end

  def handle_message([time, "r", data], state) when is_number(time) and is_binary(data) do
    [cols, rows] = String.split(data, "x")
    cols = String.to_integer(cols)
    rows = String.to_integer(rows)

    {:ok, [resize: {time, {cols, rows}}], state}
  end

  def handle_message([time, type, data], state)
      when is_number(time) and is_binary(type) and is_binary(data) do
    {:ok, [], state}
  end

  def handle_message(_message, _state) do
    {:error, :message_invalid}
  end
end
