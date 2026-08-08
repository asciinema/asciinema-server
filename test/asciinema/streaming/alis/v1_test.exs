defmodule Asciinema.Streaming.Alis.V1Test do
  use ExUnit.Case, async: true

  alias Asciinema.Streaming.Alis

  # All expected values are literal golden bytes, computed by hand from the
  # ALIS v1 spec - not roundtripped through our own decoder.

  test "magic string" do
    assert Alis.V1.magic() == <<65, 76, 105, 83, 1>>
  end

  describe "init frame" do
    test "without theme and term_init" do
      frame = Alis.V1.encode_frame({:init, %{last_id: 5, time: 100, term_size: {80, 24}}})

      assert frame == <<1, 5, 100, 80, 24, 0, 0>>
    end

    test "with multi-byte varints, 8-color theme and term_init" do
      theme = %{
        fg: {1, 2, 3},
        bg: {4, 5, 6},
        palette: for(i <- 10..17, do: {i, i, i})
      }

      frame =
        Alis.V1.encode_frame(
          {:init,
           %{
             last_id: 300,
             time: 16_384,
             term_size: {80, 24},
             term_theme: theme,
             term_init: "ab"
           }}
        )

      palette_bytes = for i <- 10..17, into: <<>>, do: <<i, i, i>>

      assert frame ==
               <<1, 172, 2, 128, 128, 1, 80, 24, 8, 1, 2, 3, 4, 5, 6>> <>
                 palette_bytes <> <<2, ?a, ?b>>
    end

    test "with 16-color theme" do
      theme = %{
        fg: {0, 0, 0},
        bg: {255, 255, 255},
        palette: for(i <- 1..16, do: {i, 0, 0})
      }

      frame =
        Alis.V1.encode_frame(
          {:init, %{last_id: 0, time: 0, term_size: {1, 1}, term_theme: theme}}
        )

      palette_bytes = for i <- 1..16, into: <<>>, do: <<i, 0, 0>>

      assert frame == <<1, 0, 0, 1, 1, 16, 0, 0, 0, 255, 255, 255>> <> palette_bytes <> <<0>>
    end

    test "crashes on a palette that is not 8 or 16 colors" do
      theme = %{fg: {0, 0, 0}, bg: {0, 0, 0}, palette: [{1, 1, 1}]}

      assert_raise MatchError, fn ->
        Alis.V1.encode_frame(
          {:init, %{last_id: 0, time: 0, term_size: {1, 1}, term_theme: theme}}
        )
      end
    end
  end

  describe "event frames" do
    test "output" do
      frame = Alis.V1.encode_frame({:output, %{id: 2, rel_time: 300, text: "hello"}})

      assert frame == <<?o, 2, 172, 2, 5>> <> "hello"
    end

    test "output with multi-byte UTF-8 text uses byte length" do
      frame = Alis.V1.encode_frame({:output, %{id: 1, rel_time: 0, text: "żółć"}})

      assert frame == <<?o, 1, 0, 8, 197, 188, 195, 179, 197, 130, 196, 135>>
    end

    test "input" do
      frame = Alis.V1.encode_frame({:input, %{id: 7, rel_time: 1, text: ""}})

      assert frame == <<?i, 7, 1, 0>>
    end

    test "resize" do
      frame = Alis.V1.encode_frame({:resize, %{id: 3, rel_time: 0, term_size: {100, 50}}})

      assert frame == <<?r, 3, 0, 100, 50>>
    end

    test "marker with varint boundary values" do
      assert Alis.V1.encode_frame({:marker, %{id: 4, rel_time: 16_383, label: ""}}) ==
               <<?m, 4, 255, 127, 0>>

      assert Alis.V1.encode_frame({:marker, %{id: 4, rel_time: 16_384, label: "x"}}) ==
               <<?m, 4, 128, 128, 1, 1, ?x>>
    end

    test "exit" do
      assert Alis.V1.encode_frame({:exit, %{id: 9, rel_time: 300, status: 1}}) ==
               <<?x, 9, 172, 2, 1>>
    end

    test "eot is a bare control frame" do
      assert Alis.V1.encode_frame({:eot, %{}}) == <<4>>
    end
  end

  describe "decode_frame/1" do
    test "decodes golden frames" do
      assert Alis.V1.decode_frame(<<1, 5, 100, 80, 24, 0, 0>>) ==
               {:ok,
                {:init,
                 %{last_id: 5, time: 100, term_size: {80, 24}, term_theme: nil, term_init: ""}}}

      assert Alis.V1.decode_frame(<<?o, 2, 172, 2, 5>> <> "hello") ==
               {:ok, {:output, %{id: 2, rel_time: 300, text: "hello"}}}

      assert Alis.V1.decode_frame(<<?i, 7, 1, 0>>) ==
               {:ok, {:input, %{id: 7, rel_time: 1, text: ""}}}

      assert Alis.V1.decode_frame(<<?r, 3, 0, 100, 50>>) ==
               {:ok, {:resize, %{id: 3, rel_time: 0, term_size: {100, 50}}}}

      assert Alis.V1.decode_frame(<<?m, 4, 255, 127, 3>> <> "ch1") ==
               {:ok, {:marker, %{id: 4, rel_time: 16_383, label: "ch1"}}}

      assert Alis.V1.decode_frame(<<?x, 9, 172, 2, 1>>) ==
               {:ok, {:exit, %{id: 9, rel_time: 300, status: 1}}}

      assert Alis.V1.decode_frame(<<4>>) == {:ok, {:eot, %{}}}
    end

    test "eot decoding ignores any payload" do
      # bare, one varint, two varints, arbitrary bytes: all mean EOT
      for frame <- [<<4>>, <<4, 100>>, <<4, 3, 50>>, <<4, "whatever">>] do
        assert Alis.V1.decode_frame(frame) == {:ok, {:eot, %{}}}
      end
    end

    test "decodes a themed init" do
      theme = %{fg: {1, 2, 3}, bg: {4, 5, 6}, palette: for(i <- 10..17, do: {i, i, i})}

      frame =
        Alis.V1.encode_frame(
          {:init, %{last_id: 1, time: 2, term_size: {80, 24}, term_theme: theme, term_init: "a"}}
        )

      assert Alis.V1.decode_frame(frame) ==
               {:ok,
                {:init,
                 %{last_id: 1, time: 2, term_size: {80, 24}, term_theme: theme, term_init: "a"}}}
    end

    test "is symmetric with encode_frame for every event type" do
      events = [
        {:output, %{id: 1, rel_time: 16_384, text: "żółć"}},
        {:input, %{id: 2, rel_time: 0, text: ""}},
        {:resize, %{id: 3, rel_time: 5, term_size: {1, 1}}},
        {:marker, %{id: 4, rel_time: 7, label: "m"}},
        {:exit, %{id: 5, rel_time: 9, status: 130}},
        {:eot, %{}}
      ]

      for event <- events do
        assert Alis.V1.decode_frame(Alis.V1.encode_frame(event)) == {:ok, event}
      end
    end

    test "rejects malformed input with errors instead of raising" do
      assert Alis.V1.decode_frame(<<>>) == {:error, :empty_frame}
      assert Alis.V1.decode_frame(<<?z, 1>>) == {:error, {:unknown_frame_type, ?z}}
      assert Alis.V1.decode_frame(<<?o, 1>>) == {:error, :truncated_varint}
      assert Alis.V1.decode_frame(<<?o, 1, 128>>) == {:error, :truncated_varint}
      assert Alis.V1.decode_frame(<<?o, 1, 0, 5, "ab">>) == {:error, :truncated_string}
      assert Alis.V1.decode_frame(<<?i, 1, 0, 0, 9>>) == {:error, :trailing_data}

      assert Alis.V1.decode_frame(<<1, 0, 0, 80, 24, 7, 0>>) ==
               {:error, {:invalid_theme_format, 7}}
    end

    test "limits varints to 10-byte u64 values" do
      eleven_bytes = :binary.copy(<<128>>, 10) <> <<1>>
      over_u64 = :binary.copy(<<128>>, 9) <> <<2>>

      assert Alis.V1.decode_frame(<<?i>> <> eleven_bytes) == {:error, :varint_too_long}
      assert Alis.V1.decode_frame(<<?i>> <> over_u64) == {:error, :varint_overflow}
    end
  end
end
