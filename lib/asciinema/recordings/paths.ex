defmodule Asciinema.Recordings.Paths do
  use Asciinema.Config

  @default_asciicast_tpl "asciicasts/{shard}/{recording_id}.{ext}"

  def path(asciicast, ext \\ nil) do
    :recording
    |> config(@default_asciicast_tpl)
    |> path(asciicast, overrides(ext))
  end

  defp path(tpl, asciicast, overrides) do
    vars =
      Map.merge(
        %{
          "{username}" => asciicast.user.username || "_user#{asciicast.user_id}",
          "{recording_id}" => to_string(asciicast.id),
          "{shard}" => shard(asciicast.id),
          "{ext}" => ext(asciicast.version)
        },
        overrides
      )

    String.replace(tpl, Map.keys(vars), &Map.get(vars, &1))
  end

  def overrides(nil), do: %{}
  def overrides(ext), do: %{"{ext}" => ext}

  defp shard(id) do
    <<a::binary-size(2), b::binary-size(2)>> =
      id
      |> Integer.to_string(10)
      |> String.pad_leading(4, "0")
      |> String.reverse()
      |> String.slice(0, 4)

    "#{a}/#{b}"
  end

  defp ext(1), do: "json"
  defp ext(2), do: "cast"
end
