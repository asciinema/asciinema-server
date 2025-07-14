defmodule AsciinemaWeb.Api.RecordingJSON do
  use AsciinemaWeb, :json
  alias AsciinemaWeb.UrlHelpers
  alias Asciinema.Accounts
  alias Ecto.Changeset

  def show(%{asciicast: asciicast, cli: cli}) do
    url = url(~p"/a/#{asciicast}")
    file_url = UrlHelpers.asciicast_file_url(asciicast)

    %{
      id: asciicast.id,
      url: url,
      file_url: file_url,
      audio_url: asciicast.audio_url,
      title: asciicast.title,
      description: asciicast.description,
      visibility: asciicast.visibility,
      message: message(url, cli)
    }
  end

  def deleted(_assigns), do: %{}

  def error(%{reason: reason} = assigns) do
    case reason do
      :unauthenticated ->
        %{type: "unauthenticated", message: "Unauthenticated"}

      :not_found ->
        %{type: "not_found", message: "Recording not found"}

      %Changeset{} = changeset ->
        details = translate_errors(changeset)
        %{type: "validation_failed", message: "Validation failed", details: details}

      :invalid_format ->
        %{type: "validation_failed", message: "This doesn't look like a valid asciicast file"}

      {:invalid_version, version} ->
        %{type: "validation_failed", message: "asciicast v#{version} is not supported"}
    end
    |> Map.merge(Map.take(assigns, [:message]))
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
    for {field, errors} <- changeset.errors do
      %{field: field, message: translate_error(errors)}
    end
  end
end
