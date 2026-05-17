defmodule Asciinema.ZstdTestHelpers do
  def zstd_fixture!(fixture_path) do
    path = Briefly.create!()
    File.write!(path, :zstd.compress(File.read!(fixture_path)))
    path
  end
end
