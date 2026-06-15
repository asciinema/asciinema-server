defmodule AsciinemaWeb.Api.AuthError do
  @moduledoc """
  Consistent HTTP responses for API auth failures, shared by the recording and
  stream controllers. All are 401: the credential is missing, malformed, revoked,
  or (`:no_account`) a well-formed installation ID that does not establish the
  account identity the operation requires.
  """

  import Plug.Conn, only: [put_status: 2, halt: 1]
  import Phoenix.Controller, only: [render: 3]

  def render_error(conn, kind) do
    {status, reason, message} = response(kind)

    conn
    |> put_status(status)
    |> render(:error, reason: reason, message: message)
    |> halt()
  end

  defp response(:missing), do: {:unauthorized, :unauthenticated, "Missing installation ID"}
  defp response(:invalid), do: {:unauthorized, :unauthenticated, "Invalid installation ID"}

  defp response(:revoked),
    do: {:unauthorized, :unauthenticated, "This installation ID has been revoked"}

  defp response(:no_account),
    do: {:unauthorized, :account_required, "This action requires an account"}
end
