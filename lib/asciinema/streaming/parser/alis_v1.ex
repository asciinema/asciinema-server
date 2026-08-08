defmodule Asciinema.Streaming.Parser.AlisV1 do
  @moduledoc """
  asciinema live stream protocol v1 parser.
  """

  # Owns the ALIS frame grammar; byte layout is the Alis.V1 codec's job.

  alias Asciinema.Streaming.Alis

  @behaviour Asciinema.Streaming.Parser

  def name, do: "v1.alis"

  def init, do: %{status: :new, time_offset: 0}

  def parse({:binary, "ALiS\x01"}, %{status: :new} = state, _now_us) do
    {:ok, [], %{state | status: :init}}
  end

  def parse({:binary, "ALiS" <> rest}, %{status: :new}, _now_us) do
    {:error, "unsupported ALiS version/configuration: #{inspect(rest)}"}
  end

  def parse({:binary, <<0x01::8, _::binary>> = frame}, %{status: status} = state, _now_us)
      when status in [:init, :eot] do
    with {:ok, {:init, init}} <- Alis.V1.decode_frame(frame) do
      {:ok, [init: init], %{state | status: :online, time_offset: init.time}}
    end
  end

  def parse({:binary, <<type::8, _::binary>> = frame}, %{status: :online} = state, _now_us)
      when type in [?o, ?i, ?r, ?m, ?x] do
    with {:ok, {event, data}} <- Alis.V1.decode_frame(frame) do
      {time, data} = absolutize(data, state.time_offset)

      {:ok, [{event, data}], %{state | time_offset: time}}
    end
  end

  def parse({:binary, <<0x04::8, _::binary>> = frame}, %{status: status} = state, _now_us)
      when status in [:init, :online] do
    with {:ok, {:eot, data}} <- Alis.V1.decode_frame(frame) do
      {:ok, [eot: data], %{state | status: :eot}}
    end
  end

  def parse({_type, _payload}, _state, _now_us) do
    {:error, :message_invalid}
  end

  def supported_commands, do: [:init, :output, :input, :resize, :marker, :exit, :eot]

  defp absolutize(%{rel_time: rel} = data, offset) do
    time = offset + rel
    data = data |> Map.delete(:rel_time) |> Map.put(:time, time)

    {time, data}
  end
end
