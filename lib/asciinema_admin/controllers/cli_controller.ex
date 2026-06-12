defmodule AsciinemaAdmin.CliController do
  use AsciinemaAdmin, :controller

  alias Asciinema.Accounts

  def create(conn, %{"user_id" => user_id, "cli" => %{"token" => token}}) do
    user = Accounts.get_user!(user_id)
    install_id = extract_install_id(token)

    case Asciinema.claim_cli(user, install_id) do
      :ok ->
        conn
        |> put_flash(:info, "CLI authorized.")
        |> redirect(to: ~p"/admin/users/#{user.id}")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Authorization failed: #{humanize(reason)}")
        |> redirect(to: ~p"/admin/users/#{user.id}")
    end
  end

  defp extract_install_id(value) do
    value
    |> String.trim()
    |> URI.parse()
    |> Map.get(:path)
    |> to_string()
    |> String.split("/")
    |> List.last()
  end

  defp humanize(:token_invalid), do: "invalid install ID — must be a UUID"
  defp humanize(:token_taken), do: "this CLI is already assigned to another user"
  defp humanize(:cli_revoked), do: "this CLI has already been revoked"
  defp humanize(other), do: to_string(other)
end
