defmodule AsciinemaWeb.ErrorJSON do
  def render(template, _assigns) do
    %{error: Phoenix.Controller.status_message_from_template(template)}
  end
end
