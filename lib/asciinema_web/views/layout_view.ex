defmodule AsciinemaWeb.LayoutView do
  use AsciinemaWeb, :view
  import AsciinemaWeb.UserHTML, only: [avatar_url: 1]

  @shade_divider String.duplicate("▒░ ░▒  ░▒░  ▒░ ░  ", 20)

  def shade_divider, do: @shade_divider

  def page_title(conn) do
    title = conn.assigns[:page_title] || "Record and share your terminal sessions, the simple way"

    "#{title} - #{conn.host}"
  end

  def color_scheme(%{assigns: %{current_user: %{ui_color_scheme: scheme}}}) do
    case scheme do
      :auto -> "dark light"
      :light -> "light"
      :dark -> "dark"
    end
  end

  def color_scheme(_conn), do: "dark light"

  def body_class(conn) do
    action = Phoenix.Controller.action_name(conn)

    controller =
      conn
      |> Phoenix.Controller.controller_module()
      |> Atom.to_string()
      |> String.replace(~r/(Elixir\.AsciinemaWeb\.)|(Controller)/, "")
      |> String.replace(".", "")
      |> Inflex.underscore()
      |> String.replace("_", " ")
      |> Inflex.parameterize()

    "c-#{controller} a-#{action}"
  end
end
