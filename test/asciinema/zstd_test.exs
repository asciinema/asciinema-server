defmodule Asciinema.ZstdTest do
  use ExUnit.Case, async: true
  alias Asciinema.Zstd

  test "stream!/2 validates chunk size" do
    assert_raise ArgumentError, fn -> Zstd.stream!("foo.zst", 0) end
    assert_raise ArgumentError, fn -> Zstd.stream!("foo.zst", -1) end
    assert_raise ArgumentError, fn -> Zstd.stream!("foo.zst", :foo) end
    assert %Zstd.Stream{} = Zstd.stream!("foo.zst", :line)
  end

  test "stream!/3 validates opts" do
    assert_raise ArgumentError, "expected opts to be a keyword list, got: :bad", fn ->
      Zstd.stream!("foo.zst", 8, :bad)
    end
  end

  test "stream!/3 rejects opts in line mode" do
    assert_raise ArgumentError,
                 "opts are not supported in :line mode, got: [compression_level: 9]",
                 fn ->
                   Zstd.stream!("foo.zst", :line, compression_level: 9)
                 end
  end

  test "stream!/2 reads and decompresses zstd data in chunks" do
    plain = String.duplicate("hello zstd\n", 100)
    path = Briefly.create!()
    File.write!(path, :zstd.compress(plain))

    assert path
           |> Zstd.stream!(17)
           |> Enum.join() == plain
  end

  test "stream!/2 handles multi-fragment zstd output" do
    plain = String.duplicate("hello zstd stream\n", 200_000)
    path = Briefly.create!()
    File.write!(path, :zstd.compress(plain))

    assert path
           |> Zstd.stream!(17)
           |> Enum.join() == plain
  end

  test "stream!/2 reads and decompresses zstd data as lines" do
    plain = "one\ntwo\nthree"
    path = Briefly.create!()
    File.write!(path, :zstd.compress(plain))

    assert path
           |> Zstd.stream!(:line)
           |> Enum.to_list() == ["one\n", "two\n", "three"]
  end

  test "stream!/2 raises on invalid zstd content when consumed" do
    path = Briefly.create!()
    File.write!(path, "not zstd")

    assert_raise RuntimeError, ~r/failed to decompress zstd stream/, fn ->
      path
      |> Zstd.stream!(8)
      |> Enum.to_list()
    end
  end

  test "stream!/2 can be collectable for zstd writing and reading roundtrip" do
    plain = IO.iodata_to_binary(["hello", " ", ["zstd", " stream"], "\n"])
    path = Briefly.create!()

    _result = Enum.into(["hello", " ", ["zstd", " stream"], "\n"], Zstd.stream!(path, 16))

    assert File.read!(path) != plain

    assert path
           |> Zstd.stream!(5)
           |> Enum.join() == plain
  end

  test "stream!/3 accepts compression options for writing" do
    plain = "hello zstd stream options"
    path = Briefly.create!()

    _result = Enum.into([plain], Zstd.stream!(path, 16, compression_level: 9))

    assert Enum.join(Zstd.stream!(path, 8)) == plain
  end

  test "collectable writes truncate existing zstd file" do
    path = Briefly.create!()

    Enum.into(["first payload"], Zstd.stream!(path, 8))
    Enum.into(["second payload"], Zstd.stream!(path, 8))

    assert Enum.join(Zstd.stream!(path, 8)) == "second payload"
  end

  test "compress_file/2 writes compressed copy" do
    plain = "hello zstd file"
    input_path = Briefly.create!()
    output_path = Briefly.create!()
    File.write!(input_path, plain)

    assert Zstd.compress_file(input_path, output_path) == output_path
    assert Enum.join(Zstd.stream!(output_path, 8)) == plain
  end

  test "compress_file/3 accepts compression options" do
    plain = "hello zstd file options"
    input_path = Briefly.create!()
    output_path = Briefly.create!()
    File.write!(input_path, plain)

    assert Zstd.compress_file(input_path, output_path, compression_level: 9) == output_path
    assert Enum.join(Zstd.stream!(output_path, 8)) == plain
  end
end
