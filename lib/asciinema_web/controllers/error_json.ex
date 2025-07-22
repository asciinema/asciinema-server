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
end
