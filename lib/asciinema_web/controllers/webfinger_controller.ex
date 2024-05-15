defmodule AsciinemaWeb.WebFingerController do
  use AsciinemaWeb, :controller
  alias Asciinema.Accounts

  def show(conn, %{"resource" => resource}) do
    resource =
      resource
      |> String.trim()
      |> String.downcase()

    with "acct:" <> acct <- resource,
         [username, domain] <- String.split(acct, "@"),
         ^domain <- AsciinemaWeb.Endpoint.host(),
         {:username, user} when not is_nil(user) <- Accounts.lookup_user(username) do
      render(conn, :show, user: user, domain: domain)
    else
      _ -> {:error, :not_found}
    end
  end
end
