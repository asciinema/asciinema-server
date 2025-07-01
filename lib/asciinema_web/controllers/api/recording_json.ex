defmodule AsciinemaWeb.Api.RecordingJSON do
  use AsciinemaWeb, :json
  alias Asciinema.Accounts
  alias Ecto.Changeset

  def created(%{asciicast: asciicast, cli: cli}) do
    url = url(~p"/a/#{asciicast}")

    %{url: url, message: message(url, cli)}
  end

  def error(%{reason: %Changeset{} = changeset}) do
    %{errors: translate_errors(changeset)}
  end

  def error(%{reason: reason}) do
    %{error: error_message(reason)}
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

      :invalid_format ->
        "This doesn't look like a valid asciicast file"

      {:invalid_version, version} ->
        "asciicast v#{version} is not supported by the server"
    end
  end

  defp message(url, cli) do
    %{token: install_id} = cli

    message = """
    View the recording at:

        #{url}
    """

    ttl = Asciinema.unclaimed_recording_ttl()

    if !Accounts.cli_registered?(cli) && ttl do
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
