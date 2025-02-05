defmodule Asciinema.RleTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  alias Asciinema.Rle

  describe "encode/2" do
    test "RLE-encodes given binary" do
      assert Rle.encode("foooobaaarrrrrrbazquxxxxx", "$") == "f$\x03obaaa$\x05rbazqu$\x04x"
    end

    test "handles empty input well" do
      assert Rle.encode("", "$") == ""
    end

    test "always encodes marker occurrences as runs" do
      assert Rle.encode("foooobaaarrrrrrbazquxxxxx", "a") ==
               "fa\x03oba\x02aa\x05rba\x00azqua\x04x"
    end

    test "handles runs over 255 well" do
      assert Rle.encode(
               "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
               "$"
             ) == "$\xffa$\x2ca"
    end
  end

  describe "decode/2" do
    test "RLE-decodes given binary" do
      assert Rle.decode("f$\x03obaaa$\x05rbazqu$\x04x", "$") == "foooobaaarrrrrrbazquxxxxx"
    end

    test "handles empty input fine" do
      assert Rle.decode("", "$") == ""
    end

    test "properly decodes marker char runs" do
      assert Rle.decode("fa\x03oba\x02aa\x05rba\x00azqua\x04x", "a") ==
               "foooobaaarrrrrrbazquxxxxx"
    end

    test "handles runs over 255 well" do
      assert Rle.decode("$\xffa$\x2ca", "$") ==
               "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    end
  end

  describe "roundtrip" do
    property "decode(encode(s)) == s" do
      check all(s <- string(:utf8)) do
        assert Rle.decode(Rle.encode(s, "\x00"), "\x00") == s
      end
    end
  end
end
