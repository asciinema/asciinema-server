defmodule AsciinemaWeb.ErrorView do
  use AsciinemaWeb, :view

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    message = Phoenix.Controller.status_message_from_template(template)

    cond do
      String.ends_with?(template, ".html") ->
        message

      String.ends_with?(template, ".json") ->
        %{error: message}

      true ->
        message
    end
  end
end
