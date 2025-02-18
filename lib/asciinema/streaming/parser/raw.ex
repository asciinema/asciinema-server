defmodule Asciinema.Streaming.Parser.Raw do
  @behaviour Asciinema.Streaming.Parser

  @default_size {80, 24}

  def name, do: "raw"

  def init, do: %{first: true, start_time: nil, last_event_id: 0}

  def parse({:binary, text}, %{first: true} = state) do
    size = size_from_resize_seq(text) || size_from_script_start_message(text) || @default_size

    commands = [
      init: %{last_id: state.last_event_id, time: 0, term_size: size, term_init: text}
    ]

    {:ok, commands, %{state | first: false, start_time: Timex.now()}}
  end

  def parse({:binary, text}, state) do
    {id, state} = get_next_id(state)
    time = stream_time(state)

    {:ok, [output: %{id: id, time: time, text: text}], state}
  end

  defp size_from_resize_seq(text) do
    with [_, rows, cols] <- Regex.run(~r/\x1b\[8;(\d+);(\d+)t/, text) do
      {String.to_integer(cols), String.to_integer(rows)}
    end
  end

  defp size_from_script_start_message(text) do
    with [_, cols, rows] <- Regex.run(~r/\[.*COLUMNS="(\d{1,3})" LINES="(\d{1,3})".*\]/, text) do
      {String.to_integer(cols), String.to_integer(rows)}
    end
  end

  defp get_next_id(state) do
    id = state.last_event_id + 1

    {id, %{state | last_event_id: id}}
  end

  defp stream_time(state), do: Timex.diff(Timex.now(), state.start_time, :microsecond)
end
