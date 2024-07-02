defmodule AsciinemaWeb.Plug.TrailingFormat do
  @known_exts ["js", "json", "cast", "txt", "svg", "png", "gif", "xml"]

  def init(opts), do: opts

  def call(conn, _opts) do
    with [last | segments] <- Enum.reverse(conn.path_info),
         [id, format] when format in @known_exts <- String.split(last, ".") do
      path_info = Enum.reverse([id | segments])
      params = Map.merge(conn.params, %{"id" => id, "_format" => format})
      path_params = Map.put(conn.path_params, "id", id)
      %{conn | path_info: path_info, params: params, path_params: path_params}
    else
      _ -> conn
    end
  end
end
