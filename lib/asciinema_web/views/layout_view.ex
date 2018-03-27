defmodule AsciinemaWeb.LayoutView do
  use AsciinemaWeb, :view
  import AsciinemaWeb.UserView, only: [avatar_url: 1]

  def page_title(conn) do
    case conn.assigns[:page_title] do
      nil -> "asciinema - Record and share your terminal sessions, the right way"
      title -> title <> " - asciinema" # TODO return safe string here?
    end
  end

  def body_class(conn) do
    action = Phoenix.Controller.action_name(conn)

    controller =
      conn
      |> Phoenix.Controller.controller_module
      |> Atom.to_string
      |> String.replace(~r/(Elixir\.AsciinemaWeb\.)|(Controller)/, "")
      |> String.replace(".", "")
      |> Inflex.underscore
      |> String.replace("_", " ")
      |> Inflex.parameterize

    "c-#{controller} a-#{action}"
  end
end
