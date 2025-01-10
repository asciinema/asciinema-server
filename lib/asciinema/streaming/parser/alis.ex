defmodule Asciinema.Streaming.Parser.Alis do
  @behaviour Asciinema.Streaming.Parser

  def init, do: %{status: :new}

  def parse({:binary, "ALiS\x01"}, %{status: :new} = state) do
    {:ok, [], %{state | status: :init}}
  end

  def parse({:binary, "ALiS" <> rest}, %{status: :new}) do
    {:error, "unsupported ALiS version/configuration: #{inspect(rest)}"}
  end

  def parse(
        {
          :binary,
          <<
            0x01,
            cols::little-16,
            rows::little-16,
            time::little-float-32,
            palette_len::8,
            rest::binary
          >>
        },
        %{status: status} = state
      )
      when status in [:init, :offline] do
    palette_len =
      case palette_len do
        0 -> 0
        # TODO: legacy, used by RC CLIs, remove after release of final CLI 3.0
        1 -> 16
        8 -> 8
        16 -> 16
      end

    theme_len = (2 + palette_len) * 3
    <<theme::binary-size(theme_len), init_len::little-32, init::binary-size(init_len)>> = rest
    theme = parse_theme(theme)

    commands = [
      reset: %{
        size: {cols, rows},
        init: init,
        time: time,
        theme: theme
      }
    ]

    {:ok, commands, %{state | status: :online}}
  end

  def parse(
        {
          :binary,
          <<
            ?o,
            time::little-float-32,
            data_len::little-32,
            data::binary-size(data_len)
          >>
        },
        %{status: :online} = state
      ) do
    {:ok, [output: {time, data}], state}
  end

  def parse(
        {
          :binary,
          <<
            ?r,
            time::little-float-32,
            cols::little-16,
            rows::little-16
          >>
        },
        %{status: :online} = state
      ) do
    {:ok, [resize: {time, {cols, rows}}], state}
  end

  def parse({:binary, <<0x04>>}, %{status: status} = state) when status in [:init, :online] do
    {:ok, [status: :offline], %{state | status: :offline}}
  end

  def parse({_type, _payload}, _state) do
    {:error, :message_invalid}
  end

  defp parse_theme(theme) do
    colors = for <<r::8, g::8, b::8 <- theme>>, do: {r, g, b}

    %{
      fg: Enum.at(colors, 0),
      bg: Enum.at(colors, 1),
      palette: Enum.slice(colors, 2..-1)
    }
  end
end
