defmodule AsciinemaAdmin.EnsureAdmin do
  @moduledoc """
  `on_mount` hook that re-checks `is_admin` on dashboard (re)connect, since
  `AdminGate` gates only the initial HTTP render, not the LiveView socket. The
  network-gated admin endpoint is exempt.
  """

  import Phoenix.LiveView, only: [redirect: 2]
  alias Asciinema.Accounts
  alias Asciinema.Accounts.User

  def on_mount(:default, _params, session, socket) do
    if socket.endpoint == AsciinemaAdmin.Endpoint or admin?(session) do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/")}
    end
  end

  defp admin?(%{"user_id" => user_id}) when not is_nil(user_id) do
    match?(%User{is_admin: true}, Accounts.get_user(user_id))
  end

  defp admin?(_session), do: false
end
