defmodule Asciinema.Streaming.Parser.Alis do
  @behaviour Asciinema.Streaming.Parser

  @theme_absent 0x00
  @theme_present 0x01

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
            @theme_absent::8,
            init_len::little-32,
            init::binary-size(init_len)
          >>
        },
        %{status: status} = state
      )
      when status in [:init, :offline] do
    {:ok, [reset: %{size: {cols, rows}, init: init, time: time, theme: nil}],
     %{state | status: :online}}
  end

  def parse(
        {
          :binary,
          <<
            0x01,
            cols::little-16,
            rows::little-16,
            time::little-float-32,
            @theme_present::8,
            theme::binary-size(18 * 3),
            init_len::little-32,
            init::binary-size(init_len)
          >>
        },
        %{status: status} = state
      )
      when status in [:init, :offline] do
    {:ok, [reset: %{size: {cols, rows}, init: init, time: time, theme: theme}],
     %{state | status: :online}}
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
    {:ok, [feed: {time, data}], state}
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
end
