defmodule Asciinema.Streaming.Parser.Json do
  alias Asciinema.Colors

  @behaviour Asciinema.Streaming.Parser

  def init, do: %{first: true}

  def parse({:text, "\n"}, state), do: {:ok, [], state}

  def parse({:text, payload}, state) do
    case Jason.decode(payload) do
      {:ok, message} ->
        handle_message(message, state)

      {:error, %Jason.DecodeError{} = reason} ->
        {:error, "JSON decode error: #{Jason.DecodeError.message(reason)}"}
    end
  end

  def handle_message(%{"cols" => cols, "rows" => rows} = header, state)
      when is_integer(cols) and is_integer(rows) do
    commands = [
      reset: %{
        size: {cols, rows},
        init: header["init"],
        time: header["time"],
        theme: parse_theme(header["theme"])
      }
    ]

    {:ok, commands, %{state | first: false}}
  end

  def handle_message(%{"width" => cols, "height" => rows} = header, state)
      when is_integer(cols) and is_integer(rows) do
    commands = [
      reset: %{
        size: {cols, rows},
        theme: parse_theme(header["theme"])
      }
    ]

    {:ok, commands, %{state | first: false}}
  end

  def handle_message(_message, %{first: true}) do
    {:error, :reset_expected}
  end

  def handle_message([time, "o", data], state) when is_number(time) and is_binary(data) do
    {:ok, [output: {time, data}], state}
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

  defp parse_theme(nil), do: nil

  defp parse_theme(%{"fg" => fg, "bg" => bg, "palette" => palette}) do
    palette =
      palette
      |> String.split(":")
      |> Enum.map(&Colors.parse/1)

    true = length(palette) == 8 or length(palette) == 16

    %{
      fg: Colors.parse(fg),
      bg: Colors.parse(bg),
      palette: palette
    }
  end
end
