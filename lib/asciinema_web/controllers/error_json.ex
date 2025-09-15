defmodule AsciinemaWeb.ErrorJSON do
  def render("400.json", _assigns) do
    %{type: "bad_request", message: "Invalid or missing request parameters"}
  end

  def render("403.json", _assigns) do
    %{type: "access_denied", message: "You don't have access to this resource"}
  end

  def render("404.json", _assigns) do
    %{type: "not_found", message: "Resource not found"}
  end

  def render("413.json", _assigns) do
    {_, limit, _, _} = AsciinemaWeb.Plug.Parsers.MULTIPART.init([])
    limit = format_byte_size(limit)

    %{
      type: "content_too_large",
      message: "The recording exceeds the server-configured size limit (#{limit})"
    }
  end

  defp format_byte_size(size) do
    cond do
      rem(size, 1024 * 1024) == 0 ->
        "#{div(size, 1024 * 1024)} MiB"

      rem(size, 1000 * 1000) == 0 ->
        "#{div(size, 1000 * 1000)} MB"

      true ->
        to_string(size)
    end
  end
end
