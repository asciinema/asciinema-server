defmodule Asciinema.Leb128Test do
  use ExUnit.Case, async: true
  use ExUnitProperties
  alias Asciinema.Leb128

  describe "encode/1" do
    test "encodes unsigned integers" do
      assert Leb128.encode(0) == <<0x00::8>>
      assert Leb128.encode(1) == <<0x01::8>>
      assert Leb128.encode(127) == <<0x7F::8>>
      assert Leb128.encode(128) == <<0x80::8, 0x01::8>>
      assert Leb128.encode(255) == <<0xFF::8, 0x01::8>>
      assert Leb128.encode(256) == <<0x80::8, 0x02::8>>
      assert Leb128.encode(16_383) == <<0xFF::8, 0x7F::8>>
      assert Leb128.encode(16_384) == <<0x80::8, 0x80::8, 0x01>>
    end
  end

  describe "decode/2" do
    test "decodes unsigned integers" do
      assert Leb128.decode(<<0x00::8>>) == {:ok, 0, ""}
      assert Leb128.decode(<<0x00::8, 0x40::8>>) == {:ok, 0, "@"}
      assert Leb128.decode(<<0x01::8>>) == {:ok, 1, ""}
      assert Leb128.decode(<<0x7F::8>>) == {:ok, 127, ""}
      assert Leb128.decode(<<0x80::8, 0x01::8>>) == {:ok, 128, ""}
      assert Leb128.decode(<<0xFF::8, 0x01::8>>) == {:ok, 255, ""}
      assert Leb128.decode(<<0x80::8, 0x02::8>>) == {:ok, 256, ""}

      assert Leb128.decode(<<0x80::8, 0x02::8, 0xAA::8, 0xBB::8>>) ==
               {:ok, 256, <<0xAA::8, 0xBB::8>>}

      assert Leb128.decode(<<0xFF::8, 0x7F::8>>) == {:ok, 16_383, ""}
      assert Leb128.decode(<<0x80::8, 0x80, 0x01::8>>) == {:ok, 16_384, ""}
    end

    test "accepts overlong encodings" do
      assert Leb128.decode(<<0x80, 0x00>>) == {:ok, 0, ""}
    end

    test "returns an error for truncated input" do
      assert Leb128.decode(<<>>) == {:error, :truncated_varint}
      assert Leb128.decode(<<0x80>>) == {:error, :truncated_varint}
    end

    test "does not limit byte count or value by default" do
      value = Integer.pow(2, 70)
      eleven_bytes = :binary.copy(<<0x80>>, 10) <> <<0x01>>

      assert Leb128.decode(eleven_bytes) == {:ok, value, ""}
    end

    test "limits encoded byte count" do
      eleven_bytes = :binary.copy(<<0x80>>, 10) <> <<0x01>>

      assert Leb128.decode(eleven_bytes, max_bytes: 10) == {:error, :varint_too_long}
    end

    test "limits decoded value" do
      u64_max = :binary.copy(<<0xFF>>, 9) <> <<0x01>>
      over_u64 = :binary.copy(<<0x80>>, 9) <> <<0x02>>
      max_value = 0xFFFF_FFFF_FFFF_FFFF

      assert Leb128.decode(u64_max, max_value: max_value) == {:ok, max_value, ""}
      assert Leb128.decode(over_u64, max_value: max_value) == {:error, :varint_overflow}
    end
  end

  describe "roundtrip" do
    test "example values" do
      for i <- [0, 1, 127, 128, 200, 500, 1000, 10_000, 100_000, 1_000_000, 10_000_000] do
        assert Leb128.decode(Leb128.encode(i)) == {:ok, i, ""}
      end
    end

    property "decode(encode(i)) == i" do
      check all(i <- positive_integer()) do
        assert Leb128.decode(Leb128.encode(i)) == {:ok, i, ""}
      end
    end
  end
end
