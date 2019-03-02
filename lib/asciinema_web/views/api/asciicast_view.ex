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
    message = """
    View the recording at:

        #{url}
    """

    is_tmp_user = Asciinema.Accounts.temporary_user?(conn.assigns.current_user)
    gc_days = Asciinema.Asciicasts.gc_days()

    if is_tmp_user && gc_days do
      hostname = AsciinemaWeb.instance_hostname()

      """
      #{message}
      This installation of asciinema recorder hasn't been linked to any #{hostname}
      account. All unclaimed recordings (from unknown installations like this one)
      are automatically archived #{gc_days} days after upload.

      If you want to preserve all recordings made on this machine, connect this
      installation with #{hostname} account by opening the following link:

          #{connect_url(conn, :show, install_id)}
      """
    else
      message
    end
  end

  def translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end
end
