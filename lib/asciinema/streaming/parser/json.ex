defmodule Asciinema.Streaming.Parser.Json do
  @moduledoc """
  asciicast v2 compatible stream protocol parser.
  """

  alias Asciinema.Colors

  @behaviour Asciinema.Streaming.Parser

  def name, do: "v2.asciicast"

  def init, do: %{first: true, last_event_id: 0}

  def parse({:text, "\n"}, state), do: {:ok, [], state}

  def parse({:text, payload}, state) do
    case Jason.decode(payload) do
      {:ok, message} ->
        handle_message(message, state)

      {:error, %Jason.DecodeError{} = reason} ->
        {:error, "JSON decode error: #{Jason.DecodeError.message(reason)}"}
    end
  end

  def handle_message(%{"width" => cols, "height" => rows} = header, state)
      when is_integer(cols) and is_integer(rows) do
    commands = [
      init: %{
        last_id: state.last_event_id,
        time: 0.0,
        term_size: {cols, rows},
        term_theme: parse_theme(header["theme"])
      }
    ]

    {:ok, commands, %{state | first: false}}
  end

  def handle_message(_message, %{first: true}) do
    {:error, :init_expected}
  end

  def handle_message([time, "o", text], state) when is_number(time) and is_binary(text) do
    {id, state} = get_next_id(state)

    {:ok, [output: %{id: id, time: time, text: text}], state}
  end

  def handle_message([time, "i", text], state) when is_number(time) and is_binary(text) do
    {id, state} = get_next_id(state)

    {:ok, [input: %{id: id, time: time, text: text}], state}
  end

  def handle_message([time, "r", data], state) when is_number(time) and is_binary(data) do
    {id, state} = get_next_id(state)
    [cols, rows] = String.split(data, "x")
    cols = String.to_integer(cols)
    rows = String.to_integer(rows)

    {:ok, [resize: %{id: id, time: time, term_size: {cols, rows}}], state}
  end

  def handle_message([time, "m", label], state) when is_number(time) and is_binary(label) do
    {id, state} = get_next_id(state)

    {:ok, [marker: %{id: id, time: time, label: label}], state}
  end

  def handle_message([time, type, data], state)
      when is_number(time) and is_binary(type) and is_binary(data) do
    {:ok, [], state}
  end

  def handle_message(_message, _state) do
    {:error, :message_invalid}
  end

  defp parse_theme(nil), do: nil

  defp parse_theme(%{"fg" => fg, "bg" => bg, "palette" => palette}) do
    palette =
      palette
      |> String.split(":")
      |> Enum.map(&Colors.parse/1)

    true = length(palette) in [8, 16]

    %{
      fg: Colors.parse(fg),
      bg: Colors.parse(bg),
      palette: palette
    }
  end

  defp get_next_id(state) do
    id = state.last_event_id + 1

    {id, %{state | last_event_id: id}}
  end
end
