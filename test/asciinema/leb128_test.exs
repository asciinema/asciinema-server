defmodule Asciinema.Leb128Test do
  use ExUnit.Case, async: true
  use ExUnitProperties
  alias Asciinema.Leb128

  describe "encode/1" do
    test "foo" do
      assert Leb128.encode(0) == <<0x00::8>>
      assert Leb128.encode(1) == <<0x01::8>>
      assert Leb128.encode(127) == <<0x7F::8>>
      assert Leb128.encode(128) == <<0x80::8, 0x01::8>>
      assert Leb128.encode(255) == <<0xFF::8, 0x01::8>>
      assert Leb128.encode(256) == <<0x80::8, 0x02::8>>
      assert Leb128.encode(16383) == <<0xFF::8, 0x7F::8>>
      assert Leb128.encode(16384) == <<0x80::8, 0x80::8, 0x01>>
    end
  end

  describe "decode/1" do
    test "bar" do
      assert Leb128.decode(<<0x00::8>>) == {0, ""}
      assert Leb128.decode(<<0x00::8, 0x40::8>>) == {0, "@"}
      assert Leb128.decode(<<0x01::8>>) == {1, ""}
      assert Leb128.decode(<<0x7F::8>>) == {127, ""}
      assert Leb128.decode(<<0x80::8, 0x01::8>>) == {128, ""}
      assert Leb128.decode(<<0xFF::8, 0x01::8>>) == {255, ""}
      assert Leb128.decode(<<0x80::8, 0x02::8>>) == {256, ""}
      assert Leb128.decode(<<0x80::8, 0x02::8, 0xAA::8, 0xBB::8>>) == {256, <<0xAA::8, 0xBB::8>>}
      assert Leb128.decode(<<0xFF::8, 0x7F::8>>) == {16383, ""}
      assert Leb128.decode(<<0x80::8, 0x80, 0x01::8>>) == {16384, ""}
    end
  end

  describe "roundtrip" do
    test "example values" do
      for i <- [0, 1, 127, 128, 200, 500, 1000, 10000, 100_000, 1_000_000, 10_000_000] do
        assert Leb128.decode(Leb128.encode(i)) == {i, ""}
      end
    end

    property "decode(encode(i)) == i" do
      check all(i <- positive_integer()) do
        assert Leb128.decode(Leb128.encode(i)) == {i, ""}
      end
    end
  end
end
