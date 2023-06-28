defmodule Asciinema.Streaming.ProducerHandler.Alis do
  @behaviour Asciinema.Streaming.ProducerHandler

  def init, do: %{first: true}

  def parse({"ALiS\x01\x00\x00\x00\x00\x00", _opts}, %{first: true} = state) do
    {:ok, [], %{state | first: false}}
  end

  def parse({"ALiS" <> rest, _opts}, %{first: true}) do
    {:error, "unsupported ALiS version/compression: #{inspect(rest)}"}
  end

  def parse(
        {
          <<
            0x01,
            cols::little-16,
            rows::little-16,
            time::little-float-32,
            init_len::little-32,
            init::binary-size(init_len)
          >>,
          _opts
        },
        state
      ) do
    {:ok, [reset: %{size: {cols, rows}, init: init, time: time}], state}
  end

  def parse(
        {
          <<
            ?o,
            time::little-float-32,
            data_len::little-32,
            data::binary-size(data_len)
          >>,
          _opts
        },
        state
      ) do
    {:ok, [feed: {time, data}], state}
  end

  def parse({<<0x04>>, _opts}, state) do
    {:ok, [offline: true], state}
  end

  def parse({_payload, _opts}, _state) do
    {:error, :message_invalid}
  end
end
