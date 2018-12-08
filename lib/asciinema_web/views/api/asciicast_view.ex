defmodule AsciinemaWeb.Api.AsciicastView do
  use AsciinemaWeb, :view

  def render("created.text", assigns) do
    message(assigns)
  end

  def render("created.json", assigns) do
    %{
      url: assigns.url,
      message: message(assigns)
    }
  end

  def render("error.json", %{changeset: changeset}) do
    %{errors: translate_errors(changeset)}
  end

  defp message(%{conn: conn, url: url, install_id: install_id}) do
    """
    View the recording at:

        #{url}

    This installation of asciinema recorder hasn't been linked to any asciinema.org
    account. All recordings from unknown installations are automatically archived
    7 days after upload.

    If you want to preserve all recordings made on this machine, connect this
    installation with asciinema.org account by opening the following link:

        #{connect_url(conn, :show, install_id)}
    """
  end

  def translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end
end
