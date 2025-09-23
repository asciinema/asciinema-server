defmodule AsciinemaWeb.Plug.Parsers.MULTIPART do
  @multipart Plug.Parsers.MULTIPART

  def init(opts), do: opts

  def parse(conn, "multipart", subtype, headers, opts) do
    opts = build_opts(opts)
    @multipart.parse(conn, "multipart", subtype, headers, opts)
  end

  def parse(conn, _type, _subtype, _headers, _opts), do: {:next, conn}

  def length_limit do
    {_, limit, _, _} = build_opts([])

    limit
  end

  defp build_opts(opts) do
    opts = if length = config(:length), do: [{:length, length} | opts], else: opts

    @multipart.init(opts)
  end

  defp config(key) do
    Keyword.get(Application.get_env(:asciinema, __MODULE__, []), key)
  end
end
