defmodule Asciinema.Quantizer do
  @moduledoc """
  Quantizer using error diffusion based on Bresenham algorithm.
  It ensures the accumulated error at any point is less than Q/2.
  """

  defstruct [:q, :error]

  def new(q), do: %__MODULE__{q: q, error: 0}

  def next(%__MODULE__{q: q, error: error} = quantizer, value) do
    error_corrected_value = value + error
    steps = div(error_corrected_value + div(q, 2), q)
    quantized_value = steps * q

    {%{quantizer | error: error_corrected_value - quantized_value}, quantized_value}
  end
end
