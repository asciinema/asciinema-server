defmodule AsciinemaWeb.TrailingFormat do
  @known_exts ["js", "json", "cast", "svg", "png", "gif", "xml"]

  def init(opts), do: opts

  def call(conn, _opts) do
    with [last | segments] <- Enum.reverse(conn.path_info),
         last_split = Enum.reverse(String.split(last, ".")),
         [format | rest] when format in @known_exts <- last_split do
      last = rest |> Enum.reverse |> Enum.join(".")
      path_info = Enum.reverse([last | segments])
      params = Map.put(conn.params, "_format", format)
      %{conn | path_info: path_info, params: params}
    else
      _ -> conn
    end
  end
end
