defmodule Asciinema.StringUtilsTest do
  use ExUnit.Case

  describe "valid_part/2" do
    import Asciinema.StringUtils, only: [valid_part: 2]

    test "no accumulator, valid string" do
      assert valid_part("", "foo") == {"foo", ""}
    end

    test "no accumulator, partial utf-8 seq" do
      assert valid_part("", <<0xC5>>) == {"", <<0xC5>>}
    end

    test "no accumulator, valid string + partial utf-8 seq at the end" do
      assert valid_part("", "foo" <> <<0xC5>>) == {"foo", <<0xC5>>}
    end

    test "with accumulator, rest of utf-8 seq + valid string at the end" do
      assert valid_part(<<0xC5>>, <<0x82>> <> "ćfoo") == {"łćfoo", ""}
    end

    test "with accumulator, mixed valid/invalid string + partial utf-8 seq at the end" do
      assert valid_part(<<0xC5>>, "x" <> <<0xC5, 0xC5>> <> "y" <> <<0xC5>>) == {"xy", <<0xC5>>}
    end
  end
end
