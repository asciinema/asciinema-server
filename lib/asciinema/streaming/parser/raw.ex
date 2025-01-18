defmodule Asciinema.Streaming.Parser.Raw do
  @behaviour Asciinema.Streaming.Parser

  @default_size {80, 24}

  def init, do: %{first: true, start_time: nil}

  def parse({:binary, text}, %{first: true} = state) do
    size = size_from_resize_seq(text) || size_from_script_start_message(text) || @default_size

    commands = [reset: %{term_size: size, term_init: text, time: 0.0}]

    {:ok, commands, %{state | first: false, start_time: Timex.now()}}
  end

  def parse({:binary, text}, state) do
    time = Timex.diff(Timex.now(), state.start_time, :microsecond) / 1_000_000

    {:ok, [output: {time, text}], state}
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
end
