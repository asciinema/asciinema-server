defmodule Asciinema.TrailingFormat do
  @known_extensions ["js", "json", "png", "gif"]

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.path_info do
      [] ->
        conn
      path_info ->
        %{conn | path_info: rewrite_path_info(path_info)}
    end
  end

  defp rewrite_path_info(path_info) do
    path_info
    |> List.last
    |> String.split(".")
    |> Enum.reverse
    |> case do
         [format | fragments] when format in @known_extensions ->
           id = fragments |> Enum.reverse |> Enum.join(".")
           path_info |> List.replace_at(-1, id) |> List.insert_at(-1, format)
         _ ->
           path_info
       end
  end
end
