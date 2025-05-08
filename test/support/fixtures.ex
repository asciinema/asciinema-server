defmodule Asciinema.Fixtures do
  def fixture(what, attrs \\ %{})

  def fixture(:upload, attrs) do
    fixture(:upload_v1, attrs)
  end

  def fixture(:upload_v1, attrs) do
    path = Map.get(attrs, :path) || "1/full.json"
    filename = Path.basename(path)

    %Plug.Upload{
      path: "test/fixtures/#{path}",
      filename: filename,
      content_type: "application/json"
    }
  end

  def fixture(:upload_v2, attrs) do
    path = Map.get(attrs, :path) || "2/full.cast"
    filename = Path.basename(path)

    %Plug.Upload{
      path: "test/fixtures/#{path}",
      filename: filename,
      content_type: "application/octet-stream"
    }
  end
end
