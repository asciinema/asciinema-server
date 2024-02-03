defmodule AsciinemaWeb.Plug.Parsers.MULTIPART do
  @multipart Plug.Parsers.MULTIPART

  def init(opts), do: opts

  def parse(conn, "multipart", subtype, headers, opts) do
    opts = if length = config(:length), do: [{:length, length} | opts], else: opts
    opts = @multipart.init(opts)

    @multipart.parse(conn, "multipart", subtype, headers, opts)
  end

  def parse(conn, _type, _subtype, _headers, _opts), do: {:next, conn}

  defp config(key) do
    Keyword.get(Application.get_env(:asciinema, __MODULE__, []), key)
  end
end
