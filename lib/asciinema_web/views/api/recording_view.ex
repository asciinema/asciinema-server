defmodule AsciinemaWeb.Api.RecordingView do
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
    ttl = Asciinema.unclaimed_recording_ttl()

    if is_tmp_user && ttl do
      hostname = AsciinemaWeb.instance_hostname()

      """
      #{message}
      This asciinema CLI hasn't been linked to any #{hostname} account.

      Recordings uploaded from unrecognized systems, such as this one, are automatically
      deleted #{ttl} days after upload.

      If you want to preserve all recordings uploaded from this machine,
      authorize this CLI with your #{hostname} account by opening the following link:

          #{Routes.connect_url(conn, :show, install_id)}
      """
    else
      message
    end
  end

  def translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end
end
