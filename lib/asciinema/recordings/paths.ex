defmodule Asciinema.Recordings.Paths do
  use Asciinema.Config

  @default_asciicast_tpl "recordings/{username}/{year}/{month}/{day}/{id}.{ext}"

  def path(asciicast, ext \\ nil) do
    :recording
    |> config(@default_asciicast_tpl)
    |> path(asciicast, overrides(ext))
  end

  defp overrides(nil), do: %{}
  defp overrides(ext), do: %{"{ext}" => ext}

  defp path(tpl, asciicast, overrides) do
    time = asciicast.inserted_at

    vars =
      Map.merge(
        %{
          "{username}" => asciicast.user.username || "_user#{asciicast.user_id}",
          "{id}" => to_string(asciicast.id),
          "{year}" => to_string(time.year),
          "{month}" => String.pad_leading(to_string(time.month), 2, "0"),
          "{day}" => String.pad_leading(to_string(time.day), 2, "0"),
          "{shard}" => shard(asciicast.id),
          "{ext}" => ext(asciicast.version)
        },
        overrides
      )

    tpl
    |> String.replace(Map.keys(vars), &Map.get(vars, &1))
    |> String.replace(~r/\{env:(\w+(\?[^}]*)?)\}/U, &resolve_env_var(&1, asciicast.env))
  end

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

  defp resolve_env_var(match, env) do
    env = env || %{}
    rest = String.slice(match, 5..-2//1)

    case String.split(rest, "?", parts: 2) do
      [name, default] ->
        Map.get(env, name, default)

      [name] ->
        Map.get(env, name, "")
    end
  end
end
