defmodule Asciinema.Streaming.ProducerHandler.Alis do
  @behaviour Asciinema.Streaming.ProducerHandler

  def init, do: %{status: :new}

  def parse({"ALiS\x01\x00\x00\x00\x00\x00", _opts}, %{status: :new} = state) do
    {:ok, [], %{state | status: :init}}
  end

  def parse({"ALiS" <> rest, _opts}, %{status: :new}) do
    {:error, "unsupported ALiS version/configuration: #{inspect(rest)}"}
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
        %{status: status} = state
      )
      when status in [:init, :offline] do
    {:ok, [reset: %{size: {cols, rows}, init: init, time: time}], %{state | status: :online}}
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
        %{status: :online} = state
      ) do
    {:ok, [feed: {time, data}], state}
  end

  def parse({<<0x04>>, _opts}, %{status: status} = state) when status in [:init, :online] do
    {:ok, [status: :offline], %{state | status: :offline}}
  end

  def parse({_payload, _opts}, _state) do
    {:error, :message_invalid}
  end
end
