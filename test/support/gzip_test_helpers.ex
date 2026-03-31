defmodule Asciinema.GzipTestHelpers do
  def gzip_fixture!(fixture_path) do
    path = Briefly.create!()
    File.write!(path, :zlib.gzip(File.read!(fixture_path)))

    path
  end
end
