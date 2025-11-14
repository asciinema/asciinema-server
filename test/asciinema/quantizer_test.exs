defmodule Asciinema.QuantizerTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  alias Asciinema.Quantizer

  describe "next/1" do
    test "returns a tuple with updated quantizer and a quantized value" do
      quantizer = Quantizer.new(1_000)

      assert {%Quantizer{}, 6_000} = Quantizer.next(quantizer, 5_555)
    end

    test "quantizes to the nearest step" do
      input = [
        026_692,
        540_290,
        064_736,
        105_951,
        171_006,
        191_943,
        107_942,
        128_108,
        148_904,
        108_973,
        211_002,
        044_701,
        489_307,
        405_987,
        105_028,
        194_590,
        061_043,
        532_296,
        319_015,
        152_786,
        032_578,
        005_445,
        040_542,
        000_756
      ]

      expected = [
        27000,
        540_000,
        65000,
        106_000,
        171_000,
        192_000,
        108_000,
        128_000,
        149_000,
        109_000,
        211_000,
        44000,
        490_000,
        406_000,
        105_000,
        194_000,
        61000,
        532_000,
        320_000,
        152_000,
        33000,
        5000,
        41000,
        1000
      ]

      quantizer = Quantizer.new(1_000)

      {_, result} =
        Enum.reduce(input, {quantizer, []}, fn input_value, {quantizer, result} ->
          {quantizer, quantized_value} = Quantizer.next(quantizer, input_value)

          {quantizer, [quantized_value | result]}
        end)

      assert Enum.reverse(result) == expected
    end
  end

  describe "invariants" do
    property "error <= q/2" do
      check all(input <- list_of(non_negative_integer())) do
        quantizer = Quantizer.new(1_000)

        Enum.reduce(input, {quantizer, 0, 0}, fn input_value,
                                                 {quantizer, input_sum, quantized_sum} ->
          {quantizer, quantized_value} = Quantizer.next(quantizer, input_value)
          input_sum = input_sum + input_value
          quantized_sum = quantized_sum + quantized_value
          error = abs(input_sum - quantized_sum)
          assert error <= 500, "error: #{error}"

          {quantizer, input_sum, quantized_sum}
        end)
      end
    end
  end
end
