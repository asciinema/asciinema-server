defmodule Asciinema.GzipTest do
  use ExUnit.Case, async: true
  alias Asciinema.Gzip

  test "stream!/2 validates chunk_size" do
    assert_raise ArgumentError, fn -> Gzip.stream!("foo.gz", 0) end
    assert_raise ArgumentError, fn -> Gzip.stream!("foo.gz", -1) end
    assert_raise ArgumentError, fn -> Gzip.stream!("foo.gz", :line) end
  end

  test "stream!/2 reads and inflates gzip data in chunks" do
    plain = String.duplicate("abc123\n", 200)
    path = Briefly.create!()
    File.write!(path, :zlib.gzip(plain))

    inflated =
      path
      |> Gzip.stream!(17)
      |> Enum.to_list()
      |> IO.iodata_to_binary()

    assert inflated == plain
  end

  test "stream!/2 supports tiny compressed read chunk sizes" do
    plain = String.duplicate("chunked data\n", 100)
    path = Briefly.create!()
    File.write!(path, :zlib.gzip(plain))

    inflated =
      path
      |> Gzip.stream!(1)
      |> Enum.to_list()
      |> IO.iodata_to_binary()

    assert inflated == plain
  end

  test "stream!/2 raises on invalid gzip content when consumed" do
    path = Briefly.create!()
    File.write!(path, "not gzip")

    assert_raise RuntimeError, ~r/failed to inflate gzip stream/, fn ->
      path
      |> Gzip.stream!(8)
      |> Enum.to_list()
    end
  end

  test "stream!/2 raises File.Error for missing files when consumed" do
    path = Path.join(System.tmp_dir!(), "missing-#{System.unique_integer([:positive])}.gz")

    assert_raise File.Error, fn ->
      path
      |> Gzip.stream!(8)
      |> Enum.to_list()
    end
  end

  test "stream!/2 can be collectable for gzip writing and reading roundtrip" do
    plain = IO.iodata_to_binary(["hello", " ", ["gzip", " stream"], "\n"])
    path = Briefly.create!()

    _result = Enum.into(["hello", " ", ["gzip", " stream"], "\n"], Gzip.stream!(path, 16))

    assert :zlib.gunzip(File.read!(path)) == plain

    inflated =
      path
      |> Gzip.stream!(5)
      |> Enum.to_list()
      |> IO.iodata_to_binary()

    assert inflated == plain
  end

  test "collectable writes truncate existing gzip file" do
    path = Briefly.create!()

    Enum.into(["first payload"], Gzip.stream!(path, 8))
    Enum.into(["second payload"], Gzip.stream!(path, 8))

    assert :zlib.gunzip(File.read!(path)) == "second payload"
  end
end
