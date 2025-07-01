defmodule AsciinemaWeb.Api.RecordingJSON do
  use AsciinemaWeb, :json

  def created(assigns) do
    %{
      url: assigns.url,
      message: message(assigns)
    }
  end

  def error(%{reason: reason}) do
    %{error: error_message(reason)}
  end

  def error(%{changeset: changeset}) do
    %{errors: translate_errors(changeset)}
  end

  defp error_message(reason) do
    case reason do
      :token_missing ->
        "Missing install ID"

      :token_not_found ->
        "Unregistered install ID"

      :token_invalid ->
        "Invalid install ID"

      :cli_revoked ->
        "Revoked install ID"

      :asciicast_not_found ->
        "asciicast not found"

      :invalid_recording_format ->
        "This doesn't look like a valid asciicast file"

      {:invalid_asciicast_version, version} ->
        "asciicast v#{version} is not supported by the server"
    end
  end

  defp message(%{cli: cli, url: url}) do
    %{user: user, token: install_id} = cli

    message = """
    View the recording at:

        #{url}
    """

    is_tmp_user = Asciinema.Accounts.temporary_user?(user)
    ttl = Asciinema.unclaimed_recording_ttl()

    if is_tmp_user && ttl do
      hostname = AsciinemaWeb.instance_hostname()
      url = url(~p"/connect/#{install_id}")

      """
      #{message}
      This asciinema CLI hasn't been linked to any #{hostname} account.

      Recordings uploaded from unrecognized systems, such as this one, are automatically
      deleted #{ttl} days after upload.

      If you want to preserve all recordings uploaded from this machine,
      authenticate this CLI with your #{hostname} account by opening the following link:

          #{url}
      """
    else
      message
    end
  end

  def translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end
end
