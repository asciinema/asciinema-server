defmodule AsciinemaWeb.LayoutView do
  use AsciinemaWeb, :view
  import AsciinemaWeb.UserView, only: [avatar_url: 1, profile_path: 1]

  def page_title(conn) do
    case conn.assigns[:page_title] do
      nil -> "asciinema - Record and share your terminal sessions, the right way"
      title -> title <> " - asciinema" # TODO return safe string here?
    end
  end
end
