defmodule AsciinemaAdmin.CliController do
  use AsciinemaAdmin, :controller
  alias Asciinema.Accounts

  def create(conn, %{"user_id" => user_id, "cli" => %{"token" => token}}) do
    user = Accounts.get_user(user_id)
    install_id = extract_install_id(token)

    case Asciinema.register_cli(user, install_id) do
      :ok ->
        redirect(conn, to: ~p"/admin/users/#{user}")

      {:error, reason} ->
        redirect(conn, to: ~p"/admin/users/#{user}?error=#{reason}")
    end
  end

  defp extract_install_id(value) do
    value
    |> URI.parse()
    |> Map.get(:path)
    |> String.split("/")
    |> List.last()
  end
end
