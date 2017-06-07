defmodule Asciinema.Fixtures do
  alias Asciinema.{Repo, Asciicasts, User}

  def fixture(:upload) do
    %Plug.Upload{path: "resources/welcome.json",
                 filename: "welcome.json",
                 content_type: "application/json"}
  end

  def fixture(:user) do
    attrs = %{username: "test",
              auth_token: "authy-auth-auth"}
    Repo.insert!(User.changeset(%User{}, attrs))
  end

  def fixture(:asciicast) do
    user = fixture(:user)
    upload = fixture(:upload)
    {:ok, asciicast} = Asciicasts.create_asciicast(user, upload)
    asciicast
  end
end
