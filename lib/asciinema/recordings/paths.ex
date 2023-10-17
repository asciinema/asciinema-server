defmodule Asciinema.Recordings.Paths do
  def sharded_path(asciicast, ext \\ nil) do
    ext =
      case {ext, asciicast.version} do
        {nil, 1} -> ".json"
        {nil, 2} -> ".cast"
        {ext, _} when is_binary(ext) -> ext
      end

    <<a::binary-size(2), b::binary-size(2)>> =
      asciicast.id
      |> Integer.to_string(10)
      |> String.pad_leading(4, "0")
      |> String.reverse()
      |> String.slice(0, 4)

    "asciicasts/#{a}/#{b}/#{asciicast.id}#{ext}"
  end
end
