defmodule Asciinema.CryptoTest do
  use ExUnit.Case, async: true

  describe "random_token/1" do
    test "returns exactly `length` alphanumeric characters" do
      for length <- [12, 16, 20, 25], _ <- 1..1_000 do
        token = Crypto.random_token(length)

        assert byte_size(token) == length
        assert token =~ ~r/^[[:alnum:]]+$/
      end
    end
  end
end
